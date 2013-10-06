class SitterWebViewController < UIViewController
  layout do
    webview = subview UIWebView, origin: [0, 0], size: [320, 640]
    url = NSBundle.mainBundle.URLForResource('sitter_details', withExtension:'html')
    webview.loadRequest NSURLRequest.requestWithURL(url)
  end
end
