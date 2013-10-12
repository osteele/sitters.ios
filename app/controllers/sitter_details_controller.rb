class SitterDetailsController < UIViewController
  attr_accessor :sitter

  layout do
    view.styleId = :sitter_details
    view.backgroundColor = 0xF9F9F9.uicolor

    url = NSBundle.mainBundle.URLForResource('sitter_details', withExtension:'html')
    @webView = subview UIWebView, delegate: self, frame: view.frame
    renderTemplate sitter if sitter

    # subview UILabel, styleId: :footer, text: 'Add to My Seven Sitters'
  end

  def sitter=(sitter)
    @sitter = sitter
    @webView.alpha = 0 if @webView # so we don't first see the previous sitter
    renderTemplate sitter if @webView
  end

  def renderTemplate(sitter)
    @templatePath ||= NSBundle.mainBundle.pathForResource('sitter_details', ofType:'html')
    @template ||= GRMustacheTemplate.templateFromContentsOfFile(@templatePath, error:nil)
    html = @template.renderObject(sitter, error:nil)
    @webView.loadHTMLString html, baseURL:NSURL.fileURLWithPath(NSBundle.mainBundle.bundlePath)
  end

  def webViewDidFinishLoad(webView)
    headerHeight = 55
    view.size = webView.size
    webView.frame = view.frame
    webView.origin = [webView.origin.x, headerHeight]
    webView.size = [webView.size.width, webView.size.height - 2 * headerHeight]

    webView.alpha = 1
  end
end
