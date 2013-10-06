class SitterViewController < UIViewController
  layout do
    view.styleId = :sitter_profile

    webView = subview UIWebView, origin: [0, 55], size: [320, 600], delegate: self
    url = NSBundle.mainBundle.URLForResource('sitter_details', withExtension:'html')
    webView.loadRequest NSURLRequest.requestWithURL(url)

    subview UIView, styleId: :header do
      dateFormatter = NSDateFormatter.alloc.init.setDateFormat('EEEE, MMMM d')
      dateText = dateFormatter.stringFromDate(NSDate.date.dateAtStartOfDay)
      subview UILabel, styleClass: :date, text: dateText #'Sunday, September 22' #
      subview UILabel, styleClass: :hours, text: '6:00–9:00 PM'
    end

    subview UILabel, styleId: :footer, text: 'Add to My Seven Sitters'
  end

  def webViewDidFinishLoad(webView)
    frame = webView.frame
    frame.size.height = 1
    webView.frame = frame
    fittingSize = webView.sizeThatFits(CGSizeZero)
    frame.size = fittingSize
    webView.frame = frame
  end
end
