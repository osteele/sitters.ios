class AppDelegate
  include BW::KVO
  BackgroundColor = UIColor.whiteColor
  FirebaseNS = 'https://sevensitters.firebaseio.com/'
  SplashFadeAnimationDuration = 0.3

  def application(application, didFinishLaunchingWithOptions:launchOptions)
    return true if RUBYMOTION_ENV == 'test'
    # TODO: process launchOptions[UIApplicationLaunchOptionsLocalNotificationKey] ?
    initializeTestFlight
    Account.instance.initialize_login_status
    registerForRemoteNotifications
    application.applicationIconBadgeNumber = 0

    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.rootViewController = UITabBarController.alloc.initWithNibName(nil, bundle:nil).tap do |controller|
      controller.viewControllers = tabControllers
      splashView = SplashController.alloc.init.view
      controller.view.addSubview splashView
      App.notification_center.observe ApplicationDidLoadDataNotification.name do |notification|
        UIView.animateWithDuration SplashFadeAnimationDuration, animations: -> { splashView.alpha = 0 }, completion: -> _ { splashView.removeFromSuperview }
      end
    end

    Storage.instance.onCachedFirebaseValue('demo/sitters') do |data|
      Sitter.updateFrom data
      NSNotificationCenter.defaultCenter.postNotification ApplicationDidLoadDataNotification
    end

    observe(ExpirationChecker.instance, 'expired') do |_, expired|
      @window.rootViewController = ExpiredController.alloc.init if expired
    end

    @window.rootViewController.wantsFullScreenLayout = true
    @window.makeKeyAndVisible
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
    @firebaseEnvironment ||= begin
      namespace = Device.simulator? ? 'development' : 'production'
      firebaseRoot[namespace]
    end
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
      SettingsController.alloc.initWithForm(SettingsController.form)
    ]
  end

  def initializeTestFlight
    return if Device.simulator?
    # return unless Object.const_defined?(:TestFlight)
    app_token = NSBundle.mainBundle.objectForInfoDictionaryKey('TESTFLIGHT_APP_TOKEN')
    # TODO remove call to TestFlight.setDeviceIdentifier before submitting to app store
    TestFlight.setDeviceIdentifier UIDevice.currentDevice.uniqueIdentifier
    TestFlight.takeOff app_token
  end
end
