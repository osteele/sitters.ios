class AppDelegate
  include BW::KVO

  private

  BackgroundColor = UIColor.whiteColor
  FirebaseNS = 'https://sevensitters.firebaseio.com/'
  SplashFadeAnimationDuration = 0.3

  public

  attr_accessor :window

  def application(application, didFinishLaunchingWithOptions:launchOptions)
    # return true if RUBYMOTION_ENV == 'test'
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
    Sitter.loadRecommendedSitters

    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    window.rootViewController = welcomeController
    case
    when demo? then setControllerForCurrentRole
    when userRole then Account.instance.loginWithRole userRole
    else Account.instance.logout
    end

    observe(Account.instance, :user) do |_, value|
      self.userRole = nil unless value
    end

    observe(self, :userRole) do |_, value|
      setControllerForCurrentRole unless value == @userRoleDisplayMode
    end

    installExpirationObserver
    presentConnectionProgressHUD

    @window.makeKeyAndVisible
    true
  end


  #
  # Storyboard Controllers
  #

  def storyboard
    @storyboard ||= UIStoryboard.storyboardWithName('Storyboard', bundle:nil)
  end

  def welcomeController
    @welcomeController ||= storyboard.instantiateInitialViewController
  end

  def parentController
    @parentController ||= UITabBarController.alloc.initWithNibName(nil, bundle:nil).tap do |controller|
      controller.viewControllers = tabControllers
      controller.wantsFullScreenLayout = true
    end
  end

  def setControllerForCurrentRole
    @userRoleDisplayMode = userRole
    case userRole
    when :parent
      window.rootViewController = parentController
      # attachSplashViewTo window.rootViewController.view
    when :sitter
      window.rootViewController = welcomeController
      window.rootViewController.performSegueWithIdentifier 'editSitterProfile', sender:self
      # presentSplashView
    else
      window.rootViewController = welcomeController
    end
  end


  #
  # User Roles and Controllers
  #

  def demo?
    NSUserDefaults.standardUserDefaults['demo']
  end

  def userRole
    return :parent if demo?
    role = App::Persistence['userRole']
    role = role.intern if role
    return role
  end

  def userRole=(role)
    return if demo?
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
    return 'development' if NSUserDefaults.standardUserDefaults['useDevelopmentServer']
    return 'production'
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
    App.run_after(0.5) do
      @connectingHUD = SVProgressHUD.showWithStatus "Connecting", maskType:SVProgressHUDMaskTypeBlack unless @splashViewShown
    end
    App.notification_center.observe ApplicationDidLoadDataNotification.name do |notification|
      @connectingHUD.dismiss if @connectingHUD
      @connectingHUD = nil
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
    return unless Object.const_defined?(:Crittercism)
    apiToken = getAPIToken('CrittercismAppId')
    return unless apiToken
    Crittercism.enableWithAppID apiToken
    @crittercismEnabled = true
    Crittercism.setValue buildNumber, forKey:'build'
    Crittercism.setValue self.demo?, forKey:'demo'
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
    mixpanel.registerSuperProperties build:buildNumber,
      demo:self.demo?,
      environment:serviceEnvironmentName
    observe(Account.instance, :user) do |_, user|
      if user
        mixpanel.createAlias user.email, forDistinctID:mixpanel.distinctId
        mixpanel.people.set({'$email' => user.email, accountKey:Account.instance.accountKey})
      end
    end
  end

  def initializeStripe
    apiToken = getAPIToken('StripePublicKey')
    return unless apiToken
    Stripe.setDefaultPublishableKey apiToken
  end

  def initializeTestFlight
    return unless Object.const_defined?(:TestFlight)
    apiToken = getAPIToken('TestflightAppToken')
    return unless apiToken
    TestFlight.setDeviceIdentifier UIDevice.currentDevice.identifierForVendor.UUIDString # UIDevice.currentDevice.uniqueIdentifier
    TestFlight.takeOff apiToken
    TestFlight.addCustomEnvironmentInformation self.demo?, forKey:'demo'
    TestFlight.addCustomEnvironmentInformation serviceEnvironmentName, forKey:'environment'
    observe(Account.instance, :user) do |_, user|
      if user
        TestFlight.addCustomEnvironmentInformation user.email, forKey:'email'
        TestFlight.addCustomEnvironmentInformation Account.instance.accountKey, forKey:'accountKey'
      end
    end
  end
end
