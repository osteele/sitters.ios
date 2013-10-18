class ChatController < UIViewController
  def initWithNibName(name, bundle:bundle)
    super
    self.tap do
      self.tabBarItem = UITabBarItem.alloc.initWithTitle('Chat', image:UIImage.imageNamed('tabs/chat'), tag:4)
    end
  end
end

class ExpiredController < UIViewController
  layout do
    textView = subview UITextView, top: 20, width: 320, height: 80,
      editable: false,
      textAlignment: NSTextAlignmentCenter,
      backgroundColor: UIColor.clearColor,
      textColor: UIColor.whiteColor,
      text: "This application has expired."
    textView.font = textView.font.fontWithSize(18)

    button = subview UIButton.buttonWithType(UIButtonTypeSystem), top: 240, width: 320, height: 50, title: 'Tap to update'
    button.font = button.font.fontWithSize(28)

    button.when_tapped do
      UIApplication.sharedApplication.openURL NSURL.URLWithString('https://testflightapp.com/m/apps')
    end
  end
end
