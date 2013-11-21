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

    Account.instance.initialize_login_status
    registerForRemoteNotifications
    application.applicationIconBadgeNumber = 0

    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    window.rootViewController = UITabBarController.alloc.initWithNibName(nil, bundle:nil).tap do |controller|
      controller.viewControllers = tabControllers
      attachSplashViewTo controller.view
    end

    Storage.instance.onCachedFirebaseValue('sitter') do |sitterData|
      Sitter.updateFrom sitterData.compact
      App.notification_center.postNotification ApplicationDidLoadDataNotification
    end

    observe(ExpirationChecker.instance, 'expired') do |_, expired|
      window.rootViewController = ExpiredController.alloc.init if expired
    end

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
          App.run_after(1) {
            @loginProgress.dismiss
            @loginProgress = nil
          }
        end
      end
    end

    window.rootViewController.wantsFullScreenLayout = true
    window.makeKeyAndVisible
    true
  end

  def buildDate
    @buildDate ||= begin
      dateString = NSBundle.mainBundle.objectForInfoDictionaryKey('BuildDate')
      NSDate.dateFromISO8601String(dateString)
    end
  end

  def firebaseRoot
    @firebaseRoot ||= Firebase.new(FirebaseNS)
  end

  def firebaseEnvironment
    @firebaseEnvironment ||= firebaseRoot[serverEnvironmentName]
  end

  def serverEnvironmentName
    return 'development' if NSUserDefaults.standardUserDefaults['simulateSitterConfirmationDelay']
    Device.simulator? ? 'development' : 'production'
  end

  #
  # Notifications
  #

  def registerForRemoteNotifications
    return if Device.simulator?
    application = UIApplication.sharedApplication
    application.registerForRemoteNotificationTypes UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert
  end

  def application(application, didRegisterForRemoteNotificationsWithDeviceToken:token)
    Logger.info "didRegisterForRemoteNotificationsWithDeviceToken %@", token
    Account.instance.deviceToken = token
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

  def attachSplashViewTo(view)
    splashView = SplashController.alloc.init.view
    view.addSubview splashView
    progress = SVProgressHUD.showWithStatus "Connecting"
    App.notification_center.observe ApplicationDidLoadDataNotification.name do |notification|
      UIView.animateWithDuration SplashFadeAnimationDuration, animations: -> { splashView.alpha = 0 }, completion: ->_ { splashView.removeFromSuperview }
      progress.dismiss
    end
  end


  #
  # Third-Party Integrations
  #

  public

  attr_reader :crittercismEnabled

  private

  def getSDKToken(name)
    NSBundle.mainBundle.objectForInfoDictionaryKey(name)
  end

  def initializeCrittercism
    return if Device.simulator?
    Crittercism.enableWithAppID getSDKToken('CrittercismAppID')
    @crittercismEnabled = true
    observe(Account.instance, :user) do |_, user|
      if user
        Crittercism.setUsername user.email
        Crittercism.setValue 'accountKey', forKey:Account.instance.accountKey
        # Crittercism.setOptOutStatus user.nil?
      end
    end
  end

  def initializeTestFlight
    return if Device.simulator?
    # return unless Object.const_defined?(:TestFlight)
    app_token = getSDKToken('TESTFLIGHT_APP_TOKEN')
    # TODO remove call to TestFlight.setDeviceIdentifier before submitting to app store
    TestFlight.setDeviceIdentifier UIDevice.currentDevice.uniqueIdentifier
    TestFlight.takeOff app_token
    observe(Account.instance, :user) do |_, user|
      if user
        TestFlight.addCustomEnvironmentInformation user.email, forKey:'email'
        TestFlight.addCustomEnvironmentInformation Account.instance.accountKey, forKey:'accountKey'
      end
    end
  end
end
