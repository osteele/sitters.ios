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
      NSNotificationCenter.defaultCenter.postNotification ApplicationDidLoadDataNotification
    end

    observe(ExpirationChecker.instance, 'expired') do |_, expired|
      window.rootViewController = ExpiredController.alloc.init if expired
    end

    App.notification_center.observe ApplicationWillAttemptLoginNotification.name do |notification|
      @loginProgress ||= MRProgressOverlayView.showOverlayAddedTo window, animated:true
      @loginProgress.titleLabelText = "Connecting"
    end

    App.notification_center.observe ApplicationDidAttemptLoginNotification.name do |notification|
      @loginProgress.dismiss true
      @loginProgress = nil
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
    NSLog "didRegisterForRemoteNotificationsWithDeviceToken %@", token
    Account.instance.deviceToken = token
  end

  def application(application, didFailToRegisterForRemoteNotificationsWithError:error)
    NSLog "didFailToRegisterForRemoteNotificationsWithError #{error.localizedDescription}"
  end

  def application(application, didReceiveRemoteNotification:notification)
    NSLog 'didReceiveRemoteNotification'
    application.applicationIconBadgeNumber = 0
  end

  # Server emulation mode uses this to emulate a message received via the Firebase queue
  def application(application, didReceiveLocalNotification:notification)
    notificationName = notification.userInfo['notificationName']
    NSLog "didReceiveLocalNotification #{notificationName}"
    userInfo = notification.userInfo
    NSNotificationCenter.defaultCenter.postNotificationName notificationName, object:self, userInfo:userInfo if notificationName
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
    App.notification_center.observe ApplicationDidLoadDataNotification.name do |notification|
      UIView.animateWithDuration SplashFadeAnimationDuration, animations: -> { splashView.alpha = 0 }, completion: ->_ { splashView.removeFromSuperview }
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
    observe(Account.instance, :user) do |previousUser, user|
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
    observe(Account.instance, :user) do |previousUser, user|
      if user
        TestFlight.addCustomEnvironmentInformation user.email, forKey:'email'
        TestFlight.addCustomEnvironmentInformation Account.instance.accountKey, forKey:'accountKey'
      end
    end
  end
end
