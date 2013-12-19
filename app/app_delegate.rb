class AppDelegate
  include BW::KVO

  private

  BackgroundColor = UIColor.whiteColor
  FirebaseNS = 'https://sevensitters.firebaseio.com/'
  SplashFadeAnimationDuration = 0.3

  public

  attr_accessor :window

  def application(application, didFinishLaunchingWithOptions:launchOptions)
    return true if RUBYMOTION_ENV == 'test'
    # TODO: process launchOptions[UIApplicationLaunchOptionsLocalNotificationKey] ?

    DDLog.addLogger DDASLLogger.sharedInstance
    DDLog.addLogger DDTTYLogger.sharedInstance

    # Initialize 3rd-party SDKs
    unless Device.simulator?
      initializeTestFlight
      initializeCrittercism
      initializeMixpanel
    end
    initializeStripe

    Account.instance.initializeLoginStatus
    registerForRemoteNotifications
    application.applicationIconBadgeNumber = 0

    Storage.instance.onCachedFirebaseValue('sitter', {cacheVersion:2}) do |sitterData|
      Sitter.updateFrom sitterData
      App.notification_center.postNotification ApplicationDidLoadDataNotification
    end

    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)

    case userRole
    when :parent, :sitter
      Account.instance.loginWithRole userRole
      presentMainController
      # presentSplashView
    else
      Account.instance.logout
      window.rootViewController = welcomeController
    end

    observe(self, :userRole) do |_, value|
      unless value == @userRoleDisplayMode
        case value
        when :parent, :sitter
          presentMainController
        else
          presentWelcomeController
        end
      end
    end

    installExpirationObserver
    presentConnectionProgressHUD

    @window.makeKeyAndVisible
    true
  end


  #
  # User Roles
  #

  def welcomeController
    @welcomeController ||= begin
      storyboard = UIStoryboard.storyboardWithName('Storyboard', bundle:nil)
      storyboard.instantiateInitialViewController
    end
  end

  def presentWelcomeController
    @userRoleDisplayMode = nil
    window.rootViewController = welcomeController
  end

  def presentMainController
    @userRoleDisplayMode = userRole
    window.rootViewController = UITabBarController.alloc.initWithNibName(nil, bundle:nil).tap do |controller|
      controller.viewControllers = tabControllers
      # attachSplashViewTo controller.view
    end
    window.rootViewController.wantsFullScreenLayout = true
  end

  def userRole
    return :parent if recordUserSettingDependency('demo')
    role = App::Persistence['userRole']
    role = role.intern if role
    return role
  end

  def userRole=(role)
    self.willChangeValueForKey :userRole
    App::Persistence['userRole'] = role
    self.didChangeValueForKey :userRole
  end

  def loginWithRole(role)
    Account.instance.loginWithRole role
  end


  #
  # Build Information
  #

  def buildDate
    @buildDate ||= begin
      dateString = NSBundle.mainBundle.objectForInfoDictionaryKey('BuildDate')
      NSDate.dateFromISO8601String(dateString)
    end
  end

  def buildNumber
    NSBundle.mainBundle.objectForInfoDictionaryKey('CFBundleVersion')
  end


  #
  # Environment
  #

  def firebaseRoot
    @firebaseRoot ||= Firebase.new(FirebaseNS)
  end

  def firebaseEnvironment
    @firebaseEnvironment ||= firebaseRoot[serviceEnvironmentName]
  end

  def serviceEnvironmentName
    return 'development' if Device.simulator?
    return 'development' if recordUserSettingDependency('useDevelopmentServer')
    return 'production'
  end


  #
  # Lifecycle
  #

  def recordUserSettingDependency(key)
    @recordedUserSettings ||= {}
    @recordedUserSettings[key] = NSUserDefaults.standardUserDefaults[key]
  end

  def applicationWillEnterForeground(application)
    @recordedUserSettings ||= {}
    changed = @recordedUserSettings.reject { |key, value|
      newValue = NSUserDefaults.standardUserDefaults[key]
      value == newValue
    }.keys.compact
    if changed.any?
      message = <<-TEXT
        The following development setting(s) have changed.
        You may need to quit and restart the application in order for it to recognize them.
      TEXT
      changed.each do |key|
        oldValue = @recordedUserSettings[key]
        newValue = NSUserDefaults.standardUserDefaults[key]
        message += "\n#{key}: #{oldValue} → #{newValue}"
        @recordedUserSettings[key] = newValue
      end
      App.alert 'Development Setting(s) Changed', message:message
    end
  end


  #
  # Notifications
  #

  def registerForRemoteNotifications
    return if Device.simulator?
    application = App.shared
    application.registerForRemoteNotificationTypes UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert
  end

  def application(application, didRegisterForRemoteNotificationsWithDeviceToken:token)
    Logger.info "didRegisterForRemoteNotificationsWithDeviceToken %@", token
    Account.instance.deviceToken = token
    Mixpanel.sharedInstance.people.addPushDeviceToken token
  end

  def application(application, didFailToRegisterForRemoteNotificationsWithError:error)
    Logger.info "didFailToRegisterForRemoteNotificationsWithError #{error.localizedDescription}"
  end

  def application(application, didReceiveRemoteNotification:notification)
    Logger.info 'didReceiveRemoteNotification'
    application.applicationIconBadgeNumber = 0
  end

  # Server emulation mode uses this to emulate a message received via the Firebase queue
  def application(application, didReceiveLocalNotification:notification)
    notificationName = notification.userInfo['notificationName']
    Logger.info "didReceiveLocalNotification #{notificationName}"
    userInfo = notification.userInfo
    App.notification_center.postNotificationName notificationName, object:self, userInfo:userInfo if notificationName
    application.applicationIconBadgeNumber = 0
  end


  #
  # Expiration
  #

  private

  def installExpirationObserver
    observe(ExpirationChecker.instance, 'expired') do |_, expired|
      window.rootViewController = ExpiredController.alloc.init if expired
    end
  end


  #
  # Views
  #

  private

  def tabControllers
    [
      BookingController.alloc.init,
      SearchSittersController.alloc.init,
      UpdatesController.alloc.init,
      ChatController.alloc.init,
      SettingsController.alloc.init
    ]
  end

  # unused
  def attachSplashViewTo(view)
    splashView = SplashController.alloc.init.view
    view.addSubview splashView
    progress = SVProgressHUD.showWithStatus "Connecting", maskType:SVProgressHUDMaskTypeBlack
    App.notification_center.observe ApplicationDidLoadDataNotification.name do |notification|
      UIView.animateWithDuration SplashFadeAnimationDuration, animations: -> { splashView.alpha = 0 }, completion: ->_ { splashView.removeFromSuperview }
      progress.dismiss
    end
  end

  def presentSplashView
    splashController = SplashController.alloc.init
    splashController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve
    window.rootViewController.presentViewController splashController, animated:false, completion:nil
    progress = nil
    state = {loaded:false}
    App.run_after(0.5) {
      progress = SVProgressHUD.showWithStatus "Connecting", maskType:SVProgressHUDMaskTypeBlack unless state[:loaded]
    }
    App.notification_center.observe ApplicationDidLoadDataNotification.name do |notification|
      progress.dismiss if progress
      state[:loaded] = true
      window.rootViewController.dismissViewControllerAnimated true, completion:nil
    end
  end

  def presentConnectionProgressHUD
    App.notification_center.observe ApplicationWillAttemptLoginNotification.name do |notification|
      @loginProgress ||= SVProgressHUD.showWithStatus "Connecting", maskType:SVProgressHUDMaskTypeBlack
    end

    App.notification_center.observe ApplicationDidAttemptLoginNotification.name do |notification|
      if @loginProgress
        if notification.userInfo[:error]
          @loginProgress.dismiss
          @loginProgress = nil
        else
          @loginProgress.showSuccessWithStatus 'Connection succeeded'
          App.run_after(0.5) {
            @loginProgress.dismiss
            @loginProgress = nil
          }
        end
      end
    end
  end


  #
  # Third-Party Integrations
  #

  public

  attr_reader :crittercismEnabled
  attr_reader :mixpanelEnabled

  # Returns the SDK token for tokenName, or nil if the bundle does not
  # provide a value for this token.
  def getAPIToken(tokenName)
    token = NSBundle.mainBundle.objectForInfoDictionaryKey(tokenName)
    Logger.warn "Token #{tokenName} is not defined" unless token
    return token
  end

  private

  def initializeCrittercism
    return if Device.simulator?
    return unless Object.const_defined?(:Crittercism)
    apiToken = getAPIToken('CrittercismAppId')
    return unless apiToken
    Crittercism.enableWithAppID apiToken
    @crittercismEnabled = true
    Crittercism.setValue buildNumber, forKey:'build'
    Crittercism.setValue serviceEnvironmentName, forKey:'environment'
    observe(Account.instance, :user) do |_, user|
      if user
        Crittercism.setUsername user.email
        Crittercism.setValue 'accountKey', forKey:Account.instance.accountKey
        # Crittercism.setOptOutStatus user.nil?
      end
    end
  end

  def initializeMixpanel
    return unless Object.const_defined?(:Mixpanel)
    apiToken = getAPIToken('MixpanelToken')
    return unless apiToken
    Mixpanel.sharedInstanceWithToken apiToken
    @mixpanelEnabled = true
    mixpanel = Mixpanel.sharedInstance
    mixpanel.identify mixpanel.distinctId
    mixpanel.registerSuperProperties({
      build:buildNumber,
      environment:serviceEnvironmentName
    })
    observe(Account.instance, :user) do |_, user|
      if user
        mixpanel.createAlias user.email, forDistinctID:mixpanel.distinctId
        mixpanel.people.set({'$email' => user.email, accountKey:Account.instance.accountKey})
      end
    end
  end

  def initializeStripe
    return unless Object.const_defined?(:Stripe)
    apiToken = getAPIToken('StripePublicKey')
    return unless apiToken
    Stripe.setDefaultPublishableKey apiToken
  end

  def initializeTestFlight
    return if Device.simulator?
    return unless Object.const_defined?(:TestFlight)
    apiToken = getAPIToken('TestflightAppToken')
    return unless apiToken
    TestFlight.setDeviceIdentifier UIDevice.currentDevice.identifierForVendor.UUIDString # UIDevice.currentDevice.uniqueIdentifier
    TestFlight.takeOff apiToken
    TestFlight.addCustomEnvironmentInformation serviceEnvironmentName, forKey:'environment'
    observe(Account.instance, :user) do |_, user|
      if user
        TestFlight.addCustomEnvironmentInformation user.email, forKey:'email'
        TestFlight.addCustomEnvironmentInformation Account.instance.accountKey, forKey:'accountKey'
      end
    end
  end
end
