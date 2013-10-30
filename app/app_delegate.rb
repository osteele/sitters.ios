class AppDelegate
  include BW::KVO
  BackgroundColor = '#A6A6A6'.to_color
  FirebaseNS = 'https://sevensitters.firebaseio.com/'
  SplashFadeAnimationDuration = 0.3

  def application(application, didFinishLaunchingWithOptions:launchOptions)
    initializeTestFlight
    Account.instance.initialize_login_status

    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.backgroundColor = BackgroundColor
    @window.rootViewController = UITabBarController.alloc.initWithNibName(nil, bundle:nil).tap do |controller|
      controller.viewControllers = tabControllers
      splashView = SplashController.alloc.init.view
      controller.view.addSubview splashView
      App.notification_center.observe ApplicationDidLoadDataNotification.name do |notification|
        UIView.animateWithDuration SplashFadeAnimationDuration, animations: -> { splashView.alpha = 0 }, completion: -> _ { splashView.removeFromSuperview }
      end
    end

    DataCache.instance.onCachedFirebaseValue(firebase, 'demo/sitters') do |data|
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
    app_token = NSBundle.mainBundle.objectForInfoDictionaryKey('TF_APP_TOKEN')
    # TODO remove call to TestFlight.setDeviceIdentifier before submitting to app store
    TestFlight.setDeviceIdentifier UIDevice.currentDevice.uniqueIdentifier
    TestFlight.takeOff app_token
  end
end
