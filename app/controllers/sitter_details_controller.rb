class SitterDetailsController < UIViewController
  attr_accessor :sitter

  layout do
    view.styleId = :sitter_details

    url = NSBundle.mainBundle.URLForResource('sitter_details', withExtension:'html')
    @webView = subview UIWebView, origin: [0, 120], size: [320, 800], delegate: self
    renderTemplate(sitter) if sitter

    subview UIView, styleId: :header do
      dateFormatter = NSDateFormatter.alloc.init.setDateFormat('EEEE, MMMM d')
      dateText = dateFormatter.stringFromDate(NSDate.date.dateAtStartOfDay)
      subview UILabel, styleClass: :date, text: dateText
      subview UILabel, styleClass: :hours, text: '6:00–9:00 PM'
    end

    subview UILabel, styleId: :footer, text: 'Add to My Seven Sitters'
  end

  def sitter=(sitter)
    @sitter = sitter
    renderTemplate(sitter) if @webView
  end

  def renderTemplate(sitter)
    @templatePath ||= NSBundle.mainBundle.pathForResource('sitter_details', ofType:'html')
    @template ||= GRMustacheTemplate.templateFromContentsOfFile(@templatePath, error:nil)
    html = @template.renderObject(sitter, error:nil)
    @webView.loadHTMLString html, baseURL:NSURL.fileURLWithPath(NSBundle.mainBundle.bundlePath)
    @webView.alpha = 0 # so we don't first see the previuos sitter
  end

  def webViewDidFinishLoad(webView)
    webView.size = [webView.size.width, 1]
    webView.size = webView.sizeThatFits(CGSizeZero)
    @webView.alpha = 1
    # UIView.animateWithDuration 0.3, animations: lambda { @webView.alpha = 1 }
  end
end
