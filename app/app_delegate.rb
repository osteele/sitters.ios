class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)

    tab_controller = UITabBarController.alloc.initWithNibName(nil, bundle:nil)
    tab_controller.viewControllers = [
      HomeController.alloc.init,
      SearchController.alloc.init,
      UpdatesController.alloc.init,
      ChatController.alloc.init,
      SettingsController.alloc.init
    ]

    @window.rootViewController = tab_controller
    @window.makeKeyAndVisible

    true
  end
end
