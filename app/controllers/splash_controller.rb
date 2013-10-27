class SplashController < UIViewController
  layout do
    subview UIImageView, :image, image: splashImage
    spinner = subview UIActivityIndicatorView.alloc.initWithActivityIndicatorStyle(UIActivityIndicatorViewStyleWhiteLarge), :spinner
    auto do
      horizontal '|-0-[image]-0-|'
      vertical '|-0-[image]-0-|'
      horizontal '|-[spinner]-|'
      vertical '|-[spinner]-|'
    end
    spinner.startAnimating
  end

  private

  def splashImage
    UIImage.imageNamed(Device.screen.height == 480 ? 'Default' : 'Default-%dh' % 568)
  end
end
