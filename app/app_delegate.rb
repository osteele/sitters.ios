class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
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
end
