class SplashController < UIViewController
  layout do
    screenHeight = UIScreen.mainScreen.bounds.size.height
    subview UIImageView,
      width: 320,
      height: screenHeight,
      image: UIImage.imageNamed(screenHeight == 480 ? 'Default' : 'Default-568h')
    spinner = subview UIActivityIndicatorView.alloc.initWithActivityIndicatorStyle(UIActivityIndicatorViewStyleWhiteLarge), :spinner
      # autoresizingMask: UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin
    auto do
      horizontal '|-[spinner]-|'
      vertical '|-[spinner]-|'
    end
    spinner.startAnimating
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
