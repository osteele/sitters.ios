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
    textView = subview UITextView, width: 320, top: 20, height: 80, textAlignment: NSTextAlignmentCenter,
      backgroundColor: UIColor.clearColor, textColor: UIColor.whiteColor,
      text: "This application has expired. \nPlease tap below to install a newer version."
    textView.font = textView.font.fontWithSize(18)

    button = subview UIButton.buttonWithType(UIButtonTypeSystem), top: 240, width: 320, title: 'Update', textAlignment: NSTextAlignmentCenter
    button.font = button.font.fontWithSize(28)
    button.when_tapped do
      UIApplication.sharedApplication.openURL NSURL.URLWithString('https://testflightapp.com/m/apps')
    end
  end
end
