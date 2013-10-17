class SitterDetailsController < UIViewController
  attr_accessor :sitter
  attr_accessor :webView

  def stylesheet
    Teacup::Stylesheet[:sitter_details]
  end

  layout do
    view.stylename = :sitter_details
    # view.backgroundColor = 0xF9F9F9.uicolor

    # headerHeight = 55
    # view.top = headerHeight
    # view.height -= headerHeight * 2

    url = NSBundle.mainBundle.URLForResource('sitter_details', withExtension:'html')
    @webView = subview UIWebView, :webview, delegate: self #, frame: view.frame

    renderTemplate if sitter

    @addButton = subview UILabel, :add_sitter,
      top: view.height - 55 - 45

    @addButton.when_tapped do
      Sitter.addSitter self.sitter
      navigationController.popViewControllerAnimated true
    end
  end

  def sitter=(sitter)
    @addButton.hidden = ! Sitter.canAdd(sitter) if @addButton
    return if @sitter == sitter
    @sitter = sitter
    renderTemplate
  end

  def renderTemplate
    return unless webView
    webView.alpha = 0
    @template ||= begin
      templatePath ||= NSBundle.mainBundle.pathForResource('sitter_details', ofType:'html')
      GRMustacheTemplate.templateFromContentsOfFile(templatePath, error:nil)
    end
    html = @template.renderObject(sitter, error:nil)
    webView.loadHTMLString html, baseURL:NSURL.fileURLWithPath(NSBundle.mainBundle.bundlePath)
  end

  def webViewDidFinishLoad(webView)
    webView.top = 55
    webView.alpha = 1
  end
end
