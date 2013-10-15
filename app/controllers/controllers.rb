class ChatController < UIViewController
  def initWithNibName(name, bundle:bundle)
    super
    self.tap do
      self.tabBarItem = UITabBarItem.alloc.initWithTitle('Chat', image:UIImage.imageNamed('tabs/chat.png'), tag:4)
    end
  end
end

class ExpiredController < UIViewController
  layout do
    subview UILabel, width: 320, height: 40, text: "Expired", textAlignment: NSTextAlignmentCenter, color: UIColor.whiteColor
  end
end
