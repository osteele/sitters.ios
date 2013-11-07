class AppDelegate
  include BW::KVO
  BackgroundColor = UIColor.whiteColor #'#A6A6A6'.to_color
  FirebaseNS = 'https://sevensitters.firebaseio.com/'
  SplashFadeAnimationDuration = 0.3

  def application(application, didFinishLaunchingWithOptions:launchOptions)
    # TODO: process launchOptions[UIApplicationLaunchOptionsLocalNotificationKey] ?
    initializeTestFlight
    Account.instance.initialize_login_status
    registerForRemoteNotifications
    registerLocalNotificationHandlers
    application.applicationIconBadgeNumber = 0

    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    # @window.backgroundColor = BackgroundColor
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
      ISO8601DateFormatter.dateFromString(dateString)
    end
  end

  def firebase
    @fb ||= Firebase.new(FirebaseNS)
  end


  #
  # Notifications
  #

  def registerForRemoteNotifications
    return if Device.simulator?
    application = UIApplication.sharedApplication
    application.registerForRemoteNotificationTypes UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert
  end

  def registerLocalNotificationHandlers
    App.notification_center.observe 'addSitter' do |notification|
      userInfo = notification.userInfo
      sitter = Sitter.findSitterById(userInfo['sitterId'])
      if sitter
        Family.instance.addSitter sitter
        App.alert 'Sitter Confirmed', message:userInfo['message']
      end
    end
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

  def application(application, didReceiveLocalNotification:notification)
    application = UIApplication.sharedApplication
    userInfo = notification.userInfo
    notificationName = notification.userInfo['notificationName']
    NSLog "didReceiveLocalNotification #{notificationName}"
    NSNotificationCenter.defaultCenter.postNotificationName notificationName, object:self, userInfo:userInfo if notificationName
    application.applicationIconBadgeNumber = [application.applicationIconBadgeNumber - notification.applicationIconBadgeNumber, 0].max
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
