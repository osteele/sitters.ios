# This class is currently used only to create the view which is then transplanted to the main navigation controller;
# not as a controller itself.
class SplashController < UIViewController
  layout do
    subview UIImageView, :image, image: splashImage
    # spinner = subview UIActivityIndicatorView.alloc.initWithActivityIndicatorStyle(UIActivityIndicatorViewStyleWhiteLarge)
    auto do
      horizontal '|-0-[image]-0-|'
      vertical '|-0-[image]-0-|'
      # horizontal '|-[spinner]-|'
      # vertical '|-[spinner]-|'
    end
    # spinner.startAnimating
  end

  private

  def splashImage
    height = Device.screen.height
    UIImage.imageNamed(height == 480 ? 'Default' : 'Default-%dh' % height)
  end
end
