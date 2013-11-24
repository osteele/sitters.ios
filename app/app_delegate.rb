class AppDelegate
  include BW::KVO

  private

  BackgroundColor = UIColor.whiteColor
  FirebaseNS = 'https://sevensitters.firebaseio.com/'
  SplashFadeAnimationDuration = 0.3

  attr_reader :window

  public

  def application(application, didFinishLaunchingWithOptions:launchOptions)
    return true if RUBYMOTION_ENV == 'test'
    # TODO: process launchOptions[UIApplicationLaunchOptionsLocalNotificationKey] ?

    DDLog.addLogger DDASLLogger.sharedInstance
    DDLog.addLogger DDTTYLogger.sharedInstance

    # Initialize 3rd-party SDKs
    initializeTestFlight
    initializeCrittercism
    initializeMixpanel
    initializeStripe

    Account.instance.initializeLoginStatus
    registerForRemoteNotifications
    application.applicationIconBadgeNumber = 0

    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    window.rootViewController = UITabBarController.alloc.initWithNibName(nil, bundle:nil).tap do |controller|
      controller.viewControllers = tabControllers
      # attachSplashViewTo controller.view
    end

    Storage.instance.onCachedFirebaseValue('sitter') do |sitterData|
      Sitter.updateFrom sitterData.compact
      App.notification_center.postNotification ApplicationDidLoadDataNotification
    end

    installExpirationObserver
    presentConnectionProgressHUD

    window.rootViewController.wantsFullScreenLayout = true
    window.makeKeyAndVisible
    presentSplashView
    true
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
    @firebaseEnvironment ||= firebaseRoot[serverEnvironmentName]
  end

  def serverEnvironmentName
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
      false
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
    # splashController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal
    window.rootViewController.presentViewController splashController, animated:false, completion:nil
    progress = SVProgressHUD.showWithStatus "Connecting", maskType:SVProgressHUDMaskTypeBlack
    App.notification_center.observe ApplicationDidLoadDataNotification.name do |notification|
      window.rootViewController.dismissViewControllerAnimated true, completion:nil
      progress.dismiss
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
    token = getAPIToken('CrittercismAppId')
    return unless token
    Crittercism.enableWithAppID token
    @crittercismEnabled = true
    Crittercism.setValue buildNumber, forKey:'build'
    Crittercism.setValue serverEnvironmentName, forKey:'environment'
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
    token = getAPIToken('MixpanelToken')
    return unless token
    Mixpanel.sharedInstanceWithToken token
    @mixpanelEnabled = true
    mixpanel = Mixpanel.sharedInstance
    mixpanel.registerSuperProperties({
      build:buildNumber,
      environment:serverEnvironmentName
    })
    observe(Account.instance, :user) do |_, user|
      if user
        mixpanel.createAlias user.email, forDistinctID:mixpanel.distinctId
        mixpanel.identify mixpanel.distinctId
        mixpanel.people.set({'$email' => user.email, accountKey:Account.instance.accountKey})
      end
    end
  end

  def initializeStripe
    return unless Object.const_defined?(:Stripe)
    token = getAPIToken('StripePublicKey')
    return unless token
    Stripe.setDefaultPublishableKey token
  end

  def initializeTestFlight
    return if Device.simulator?
    return unless Object.const_defined?(:TestFlight)
    token = getAPIToken('TestflightAppToken')
    return unless token
    # TODO remove call to TestFlight.setDeviceIdentifier before submitting to app store
    TestFlight.setDeviceIdentifier UIDevice.currentDevice.uniqueIdentifier
    TestFlight.takeOff token
    TestFlight.addCustomEnvironmentInformation serverEnvironmentName, forKey:'environment'
    observe(Account.instance, :user) do |_, user|
      if user
        TestFlight.addCustomEnvironmentInformation user.email, forKey:'email'
        TestFlight.addCustomEnvironmentInformation Account.instance.accountKey, forKey:'accountKey'
      end
    end
  end
end
