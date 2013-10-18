class SitterDetailsController < UIViewController
  attr_accessor :sitter
  attr_accessor :webView

  def stylesheet
    Teacup::Stylesheet[:sitter_details]
  end

  layout do
    view.stylename = :sitter_details

    url = NSBundle.mainBundle.URLForResource('sitter_details', withExtension:'html')
    @webView = subview UIWebView, :webview, delegate: self

    @addBSitterButton = subview UILabel, :add_sitter_button
    @addBSitterButton.when_tapped do
      Sitter.addSitter self.sitter
      navigationController.popViewControllerAnimated true
    end

    auto do
      # metrics 'timesel_bottom' => 119
      vertical '|-119-[webview]-0-[add_sitter_button(55)]-45-|'
      horizontal '|-0-[add_sitter_button(320)]-0-|'
    end

    renderTemplate if sitter
  end

  def sitter=(sitter)
    @addBSitterButton.hidden = ! Sitter.canAdd(sitter) if @addBSitterButton
    return if @sitter == sitter
    @sitter = sitter
    renderTemplate
  end

  def renderTemplate
    return unless webView
    webView.hidden = true
    webView.alpha = 0
    @template ||= begin
      templatePath ||= NSBundle.mainBundle.pathForResource('sitter_details', ofType:'html')
      GRMustacheTemplate.templateFromContentsOfFile(templatePath, error:nil)
    end
    html = @template.renderObject(sitter, error:nil)
    webView.loadHTMLString html, baseURL:NSURL.fileURLWithPath(NSBundle.mainBundle.bundlePath)
  end

  def webViewDidFinishLoad(webView)
    webView.hidden = false
    webView.alpha = 1
  end
end
