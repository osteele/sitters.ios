FirebaseNS = 'https://sevensitters.firebaseio.com/'

class AppDelegate
  include BW::KVO

  def application(application, didFinishLaunchingWithOptions:launchOptions)
    initializeTestFlight
    Account.instance.check

    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.backgroundColor = '#A6A6A6'.to_color
    @window.rootViewController = SplashController.alloc.init

    withSyncedData('demo/sitters') do |data|
      Sitter.initializeFromJSON data
      didFinishLoadingData
    end

    observe(ExpirationChecker.instance, 'expired') do |_, value|
      @window.rootViewController = ExpiredController.alloc.init if value
    end

    @window.rootViewController.wantsFullScreenLayout = true
    @window.makeKeyAndVisible
    true
  end

  def didFinishLoadingData()
    return if ExpirationChecker.instance.expired
    @window.rootViewController = UITabBarController.alloc.initWithNibName(nil, bundle:nil).tap do |controller|
      controller.viewControllers = tabControllers
    end
  end

  def buildDate
    @buildDate ||= begin
        dateString = NSBundle.mainBundle.objectForInfoDictionaryKey('BuildDate')
        ISODateFormatter.dateFromString(dateString)
      end
  end

  def firebase
    @fb ||= Firebase.new(FirebaseNS)
  end

  private

  def withSyncedData(key, &block)
    data = DataCache.instance.withJSONCache(key, version:1)
    if data
      Dispatch::Queue.main.async do block.call data end
    else
      firebase[key].once(:value) do |snapshot|
        data = snapshot.value
        DataCache.instance.withJSONCache(key, version:1) do data end
        block.call data
      end
    end
  end

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
