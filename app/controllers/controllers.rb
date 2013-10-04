class SearchController < UIViewController
  def initWithNibName(name, bundle:bundle)
    super
    self.tabBarItem = UITabBarItem.alloc.initWithTitle('Search', image:UIImage.imageNamed('search.png'), tag:2)
    self
  end
end

class UpdatesController < UIViewController
  def initWithNibName(name, bundle:bundle)
    super
    self.tabBarItem = UITabBarItem.alloc.initWithTitle('Updates', image:UIImage.imageNamed('updates.png'), tag:3)
    self
  end
end

class ChatController < UIViewController
  def initWithNibName(name, bundle:bundle)
    super
    self.tabBarItem = UITabBarItem.alloc.initWithTitle('Chat', image:UIImage.imageNamed('chat.png'), tag:4)
    self
  end
end

class SettingsController < UIViewController
  def initWithNibName(name, bundle:bundle)
    super
    self.tabBarItem = UITabBarItem.alloc.initWithTitle('Settings', image:UIImage.imageNamed('settings.png'), tag:5)
    self
  end
end
