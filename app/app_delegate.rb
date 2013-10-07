class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    registerWithTestFlight
    initializePixmate

    window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)

    # tab_controller = UITabBarController.alloc.initWithNibName(nil, bundle:nil)
    # tab_controller.viewControllers = tabControllerss
    # window.rootViewController = tab_controller

    window.rootViewController = UITabBarController.alloc.initWithNibName(nil, bundle:nil).tap do |controller|
      controller.viewControllers = tabControllers
    end

    # window.rootViewController = SitterViewController.alloc.init
    # window.rootViewController = SettingsController.alloc.initWithForm(SettingsController.form)
    window.styleMode = PXStylingNormal

    window.makeKeyAndVisible
    true
  end

  private

  def tabControllers
    [
      SittersController.alloc.init,
      SearchController.alloc.init,
      UpdatesController.alloc.init,
      ChatController.alloc.init,
      SettingsController.alloc.initWithForm(SettingsController.form)
    ]
  end

  def initializePixmate
    if Device.simulator?
      stylesheet_path = ENV['PX_STYLESHEET_PATH']
      PXStylesheet.styleSheetFromFilePath stylesheet_path, withOrigin:0
      PXStylesheet.currentApplicationStylesheet.monitorChanges = true
    end
  end

  def registerWithTestFlight
    return unless Device.simulator?
    return unless Object.const_defined?('TestFlight')
    app_token = NSBundle.mainBundle.objectForInfoDictionaryKey('TF_APP_TOKEN')
    # TODO remove call to TestFlight.setDeviceIdentifier before submitting to app store
    TestFlight.setDeviceIdentifier UIDevice.currentDevice.uniqueIdentifier
    TestFlight.takeOff app_token
  end
end
