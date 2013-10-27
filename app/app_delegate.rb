FirebaseNS = 'https://sevensitters.firebaseio.com/'

class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    initializeTestFlight

    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.rootViewController = SplashController.alloc.init

    withSyncedData('demo/sitters') do |data|
      Sitter.initializeFromJSON data
      didFinishLoadingData
    end

    firebase['expirationDate'].on(:value) do |snapshot|
      dateDateFormatter = NSDateFormatter.alloc.init.setDateFormat("yyyy-MM-dd'T'HH:mm:ssZ")
      date = dateDateFormatter.dateFromString(snapshot.value)
      didExpire if date and buildDate < date
    end

    Account.instance.check

    didExpire if isExpired
    @window.rootViewController.wantsFullScreenLayout = true
    @window.makeKeyAndVisible
    true
  end

  def didFinishLoadingData()
    return if isExpired
    @window.rootViewController = UITabBarController.alloc.initWithNibName(nil, bundle:nil).tap do |controller|
      controller.viewControllers = tabControllers
    end
  end

  def didExpire
    @expired = true
    @window.rootViewController = ExpiredController.alloc.init
  end

  def buildDate
    @buildDate ||= dateFromProperty('BuildDate')
  end

  def expirationDate
    @expirationDate ||= dateFromProperty('ExpirationDate')
  end

  def firebase
    @fb ||= Firebase.new(FirebaseNS)
  end

  private

  def withSyncedData(key, &block)
    data = DataCache.instance.withJSONCache(key, version:1)
    return block.call data if data
    firebase[key].once(:value) do |snapshot|
      data = snapshot.value
      DataCache.instance.withJSONCache(key, version:1) do data end
      block.call data
    end
  end

  def dateFromProperty(propertyName)
    dateString = NSBundle.mainBundle.objectForInfoDictionaryKey(propertyName)
    return nil unless dateString
    dateDateFormatter = NSDateFormatter.alloc.init.setDateFormat("yyyy-MM-dd'T'HH:mm:ssZ")
    dateDateFormatter.dateFromString(dateString)
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

  def isExpired
    return @expired unless expirationDate
    return expirationDate < NSDate.date
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
