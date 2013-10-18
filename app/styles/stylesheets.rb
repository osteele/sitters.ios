Teacup::Stylesheet.new :sitter_details do
  lightFont = UIFont.fontWithName('Helvetica-Light', size:18)

  style :sitter_details,
    backgroundColor: 0xF9F9F9.uicolor;

  style :webview,
    constraints: [
      constrain_top(119),
      constrain(:left).equals(:superview, :left),
      constrain(:width).equals(:superview, :width),
      constrain(:bottom).equals(:superview, :bottom) #.minus(105)
    ]

  style :add_sitter,
    left: 0,
    width: 320,
    height: 55,
    backgroundColor: 0x6A9CD0.uicolor,
    textColor: UIColor.whiteColor,
    text: 'Add to My Seven Sitters',
    font: lightFont.fontWithSize(20),
    textAlignment: NSTextAlignmentCenter;
end

Teacup::Stylesheet.new :sitters do
  font = UIFont.fontWithName('Helvetica', size:18)
  boldFont = UIFont.fontWithName('Helvetica-Bold', size:18)

  style :sitters,
    top: 120,
    backgroundColor: 0xF9F9F9.uicolor;

  style :scroll,
    constraints: [
      constrain(:top).equals(:superview, :top),
      constrain(:left).equals(:superview, :left),
      constrain(:width).equals(:superview, :width),
      constrain(:height).equals(:superview, :height)
    ]

  style :avatars,
    origin: [0, 88],
    size: [320, 300];

  style :sitter,
    width: 90,
    height: 90,
    backgroundColor: UIColor.clearColor;

  style :add_sitters_text,
    top: 340,
    width: 320,
    height: 45,
    textColor: 0x5481C9.uicolor,
    font: boldFont.fontWithSize(13),
    textAlignment: NSTextAlignmentCenter;

  style :add_sitters_caption,
    top: 353,
    left: 10,
    width: 320,
    height: 45,
    textColor: 0x969696.uicolor,
    font: font.fontWithSize(11),
    textAlignment: NSTextAlignmentCenter,
    text: 'to enjoy complete freedom and spontaneity.';

  style :big_button,
    top: 391,
    width: 152,
    height: 45,
    layer: { cornerRadius: 3 };

  style :recommended_sitters_button, extends: :big_button,
    left: 6,
    backgroundColor: 0x5582C3.uicolor;

  style :invite_sitter_button, extends: :big_button,
    left: 163,
    backgroundColor: 0xA6A6A6.uicolor;

  style :big_button_label,
    left: 0,
    top: -9,
    width: 150,
    height: 50,
    textColor: UIColor.whiteColor,
    font: font.fontWithSize(13),
    textAlignment: NSTextAlignmentCenter;

  style :big_button_caption,
    left: 0,
    top: 7,
    width: 150,
    height: 45,
    textColor: UIColor.whiteColor,
    font: UIFont.fontWithName('Helvetica-Light', size:11),
    textAlignment: NSTextAlignmentCenter;
end

Teacup::Stylesheet.new :booking do
  font = UIFont.fontWithName('Helvetica', size:18)

  style :sitter,
    width: 90,
    height: 90;

  style :time_selector,
    top: 20,
    width: 320,
    height: 120;

  style UILabel,
    textColor: UIColor.whiteColor,
    textAlignment: NSTextAlignmentCenter;

  style :day_of_week,
    width: 44,
    height: 34,
    top: 30,
    font: font.fontWithSize(18);

  style :day_of_week_overlay,
    width: 44,
    height: 34,
    top: 30,
    font: font.fontWithSize(18),
    textColor: 0x5481C9.uicolor;

  style :day_selection_marker,
    left: 8,
    top: 30,
    width: 34,
    height: 34,
    backgroundColor: UIColor.whiteColor,
    layer: {
      cornerRadius: 17,
      shadowRadius: 1.5,
      shadowOffset: [0, 2],
      shadowOpacity: 0.5
    };

  style :hour_slider,
    left: 10,
    top: 75,
    width: 195,
    height: 35,
    backgroundColor: UIColor.whiteColor,
    layer: {
      cornerRadius: 17,
      shadowRadius: 3,
      shadowOffset: [0, 1],
      shadowOpacity: 0.5
    };

  style :hour_slider_label,
    width: 195,
    height: 35,
    textColor: 0x5481C9.uicolor;

  style :hour_drag_handle,
    constraints: [
      constrain(:top).equals(:superview, :top),
      constrain(:left).equals(:superview, :left),
      constrain(:width).equals(:superview, :width),
      constrain(:height).equals(:superview, :height)
    ]

  style :hour_left_handle,
      left: 0,
      top: 0,
      width: 40,
      height: 35;

  style :hour_right_handle,
    constraints: [
      constrain(:top).equals(:superview, :top),
      constrain(:height).equals(:superview, :height),
      constrain(:right).equals(:superview, :right).plus(20),
      constrain_width(40)
    ]

  style :hour_left_handle_image,
    image: UIImage.imageNamed('images/left-drag-handle'),
    left: 4,
    top: 10,
    width: 6,
    height: 15;

  style :hour_right_handle_image,
    width: 6,
    height: 15,
    top: 10,
    left: 9,
    image: UIImage.imageNamed('images/right-drag-handle');

  style :hour_blob,
    top: 70,
    width: 40,
    height: 40;

  style :hour_blob_hour,
    left: 0,
    top: 8,
    width: 20,
    height: 20,
    font: font.fontWithSize(14),
    textColor: UIColor.whiteColor,
    textAlignment: NSTextAlignmentCenter;

  style :hour_blob_am_pm,
    top: 20,
    width: 20,
    height: 20,
    font: font.fontWithSize(9),
    textColor: UIColor.whiteColor,
    textAlignment: NSTextAlignmentCenter;

  style :hour_blob_half_past,
    left: 26,
    top: 13,
    width: 20,
    height: 20,
    textColor: 0xA8C1E5.uicolor,
    font: font.fontWithSize(13),
    textAlignment: NSTextAlignmentRight;

  style :time_selector,
    # top: 20,
    # width: 320
    # height: 120
    gradient:  { colors: [0x6FA1EB.uicolor, 0x4E7EC2.uicolor] }

  style :date,
    width: 320,
    height: 20,
    top: 5,
    font: font.fontWithSize(12)
end
