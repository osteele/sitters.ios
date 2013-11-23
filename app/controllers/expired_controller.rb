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
      App.open_url 'https://testflightapp.com/m/apps'
    end
  end
end
