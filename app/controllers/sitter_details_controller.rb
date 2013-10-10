class SitterDetailsController < UIViewController
  attr_accessor :sitter

  layout do
    view.styleId = :sitter_details

    url = NSBundle.mainBundle.URLForResource('sitter_details', withExtension:'html')
    @webView = subview UIWebView, origin: [0, 55], size: [320, 600], delegate: self
    @webView.loadRequest NSURLRequest.requestWithURL(url)

    subview UIView, styleId: :header do
      dateFormatter = NSDateFormatter.alloc.init.setDateFormat('EEEE, MMMM d')
      dateText = dateFormatter.stringFromDate(NSDate.date.dateAtStartOfDay)
      subview UILabel, styleClass: :date, text: dateText
      subview UILabel, styleClass: :hours, text: '6:00–9:00 PM'
    end

    subview UILabel, styleId: :footer, text: 'Add to My Seven Sitters'
  end

  def webViewDidFinishLoad(webView)
    @webView.size = [webView.size.width, 1]
    @webView.size = webView.sizeThatFits(CGSizeZero)
  end
end
