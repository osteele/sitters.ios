class TimeSelectionView < UIView
  include PM::Styling

  def self.new
    view = alloc.initWithFrame(CGRectZero)
    view
  end

  def initWithFrame(frame)
    super
    set_attributes self, {
      background_color: hex_color("5582C3"),
      # layer: {
      #   shadow_radius: 4.0,
      #   shadow_opacity: 0.4,
      #   shadow_color: UIColor.blackColor.CGColor
      # }
    }
    self
  end
end
