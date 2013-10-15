class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    initializeTestFlight
    initializePixmate

    window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    window.rootViewController = UITabBarController.alloc.initWithNibName(nil, bundle:nil).tap do |controller|
      controller.viewControllers = tabControllers
    end

    # window.rootViewController = SuggestedSittersController.alloc.init
    # window.rootViewController = SitterDetailsController.alloc.init.tap do |c| c.sitter = Sitter.all.first end
    # window.rootViewController = SettingsController.alloc.initWithForm(SettingsController.form)

    window.rootViewController = ExpiredController.alloc.init if isExpired

    window.styleMode = PXStylingNormal
    window.makeKeyAndVisible
    true
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

  def isExpired
    expirationString = NSBundle.mainBundle.objectForInfoDictionaryKey('EXPIRATION_DATE')
    return false unless expirationString
    expirationDateFormatter = NSDateFormatter.alloc.init.setDateFormat("yyyy-MM-dd'T'HH:mm:ssZ")
    expirationDate = expirationDateFormatter.dateFromString(expirationString)
    # puts "Expires #{NSDateFormatter.alloc.init.setDateFormat(NSDateFormatterMediumStyle).stringFromDate(expirationDate)}"
    return expirationDate < NSDate.date
  end

  def initializePixmate
    if Device.simulator?
      stylesheet_path = ENV['PX_STYLESHEET_PATH']
      PXStylesheet.styleSheetFromFilePath stylesheet_path, withOrigin:0
      PXStylesheet.currentApplicationStylesheet.monitorChanges = true
    end
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
