class ChatController < UIViewController
  def initWithNibName(name, bundle:bundle)
    super
    self.tap do
      self.tabBarItem = UITabBarItem.alloc.initWithTitle('Chat', image:UIImage.imageNamed('chat.png'), tag:4)
    end
  end
end

class SettingsController < UIViewController
  def initWithNibName(name, bundle:bundle)
    super
    self.tap do
      self.tabBarItem = UITabBarItem.alloc.initWithTitle('Settings', image:UIImage.imageNamed('settings.png'), tag:5)
    end
  end
end
