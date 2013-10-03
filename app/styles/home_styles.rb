# This is a fairly limited way to style your application.
# For more complex apps, we recommend Teacup. https://github.com/rubymotion/teacup
module HomeStyles
  def add_sitters_label_view
    {
      text: "Add five more sitters",
      text_color: hex_color("5481C9"),
      background_color: UIColor.clearColor,
      # shadow_color: UIColor.blackColor,
      number_of_lines: 0,
      text_alignment: UITextAlignmentCenter,
      font: UIFont.systemFontOfSize(13.0),
      # resize: [ :left, :right, :top ], # ProMotion sugar here
      frame: CGRectMake(10, 405, 300, 45)
    }
  end

  def add_sitters_label_caption_view
    {
      text: "to enjoy complete freedom and spontaneity.",
      text_color: hex_color("#969696"),
      background_color: UIColor.clearColor,
      # shadow_color: UIColor.blackColor,
      number_of_lines: 0,
      text_alignment: UITextAlignmentCenter,
      font: UIFont.systemFontOfSize(12.0),
      # resize: [ :left, :right, :top ], # ProMotion sugar here
      frame: CGRectMake(10, 415, 300, 45)
    }
  end
end
