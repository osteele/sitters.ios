class SitterDetailsController < UIViewController
  attr_accessor :sitter
  attr_accessor :webView
  attr_accessor :action
  attr_accessor :delegate

  def stylesheet
    Teacup::Stylesheet[:sitter_details]
  end

  layout do
    view.stylename = :sitter_details

    url = NSBundle.mainBundle.URLForResource('sitter_details', withExtension:'html')
    @webview = subview UIWebView, :webview, delegate: self

    @action_button = subview UILabel, :action_button
    @action_button.when_tapped do
      delegate.action @action, sitter:sitter
      navigationController.popViewControllerAnimated true
    end

    auto do
      metrics 'header_h' => 55, 'action_button_h' => 55, 'footer_h' => 45
      vertical '|-header_h-[webview]-0-[action_button(action_button_h)]-footer_h-|'
      horizontal '|-0-[action_button]-0-|'
    end

    renderTemplate if sitter
  end

  def sitter=(sitter)
    return if @sitter == sitter
    @sitter = sitter
    renderTemplate
  end

  private

  attr_reader :webview
  attr_reader :action_button

  def updateButtonText
    return unless @action_button and @action
    @action_button.text = case action
      when :add then 'Add to My Seven Sitters'
      when :reserve then 'Book this sitter'
      when :request then 'Request this sitter'
    end
  end

  def renderTemplate
    return unless webview
    webview.hidden = true
    @template ||= begin
      templatePath ||= NSBundle.mainBundle.pathForResource('sitter_details', ofType:'html')
      GRMustacheTemplate.templateFromContentsOfFile(templatePath, error:nil)
    end
    html = @template.renderObject(sitter, error:nil)
    webview.loadHTMLString html, baseURL:NSURL.fileURLWithPath(NSBundle.mainBundle.bundlePath)
  end

  def webViewDidFinishLoad(webview)
    webview.hidden = false
    updateButtonText
  end
end
