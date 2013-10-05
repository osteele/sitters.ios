class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    registerWithTestFlight

    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)

    tab_controller = UITabBarController.alloc.initWithNibName(nil, bundle:nil)
    tab_controller.viewControllers = [
      SittersController.alloc.init,
      SearchController.alloc.init,
      UpdatesController.alloc.init,
      ChatController.alloc.init,
      SettingsController.alloc.init
    ]

    @window.rootViewController = tab_controller
    @window.styleMode = PXStylingNormal

    if Device.simulator?
      PXStylesheet.styleSheetFromFilePath ENV['PX_STYLESHEET_PATH'], withOrigin:0 if ENV['PX_STYLESHEET_PATH']
      PXStylesheet.currentApplicationStylesheet.monitorChanges = true
    end

    @window.makeKeyAndVisible
    true
  end

  private

  def registerWithTestFlight
    return unless Object.const_defined?('TestFlight')
    return if UIDevice.currentDevice.model.include?('Simulator')
    app_token = NSBundle.mainBundle.objectForInfoDictionaryKey('TF_APP_TOKEN')
    # TODO remove call to TestFlight.setDeviceIdentifier before submitting to app store
    TestFlight.setDeviceIdentifier UIDevice.currentDevice.uniqueIdentifier
    TestFlight.takeOff app_token
  end
end
