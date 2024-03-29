DragHandleMargin = 7

Teacup::Stylesheet.new :sitter_details do
  lightFont = UIFont.fontWithName('Helvetica-Light', size:18)

  style :web_view,
    backgroundColor: '#F9F9F9'.to_color,
    constraints: [
      constrain(:left).equals(:superview, :left),
      constrain(:width).equals(:superview, :width),
    ]

  style :action_button,
    backgroundColor: '#6A9CD0'.to_color,
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
    backgroundColor: '#F9F9F9'.to_color;

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
    textColor: '#5481C9'.to_color,
    font: boldFont.fontWithSize(13),
    textAlignment: NSTextAlignmentCenter;

  style :add_sitters_caption,
    top: 353,
    left: 10,
    width: 320,
    height: 45,
    textColor: '#969696'.to_color,
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
    backgroundColor: '#5582C3'.to_color;

  style :invite_sitter_button, extends: :big_button,
    left: 163,
    backgroundColor: '#A6A6A6'.to_color;

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
  time_selector_gradient_colors = ['#6FA1EB'.to_color, '#4E7EC2'.to_color]

  style :status_bar_background,
    frame: [[0, 0], [320, 20]],
    backgroundColor: time_selector_gradient_colors.first

  style :sitter,
    width: 90,
    height: 90;

  style :time_selector,
    top: 20,
    width: 320,
    height: 120,
    gradient:  { colors: time_selector_gradient_colors };

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
    textColor: '#5481C9'.to_color;

  style :day_indicator,
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

  style :day_indicator_handle,
    constraints: [
      constrain(:top).equals(:day_indicator, :top).minus(DragHandleMargin),
      constrain(:left).equals(:day_indicator, :left).minus(DragHandleMargin),
      constrain(:right).equals(:day_indicator, :right).plus(DragHandleMargin),
      constrain(:bottom).equals(:day_indicator, :bottom).plus(DragHandleMargin),
    ];

  style :hours_indicator,
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
    # constraints: [
    #   constrain_height(35),
    #   constrain_width(135),
    #   constrain(:bottom).equals(:superview, :bottom)
    # ];

  style :hours_indicator_label,
    width: 195,
    height: 35,
    # require Neueu, since it has a Bold Condensed variant
    font: UIFont.fontWithName('Helvetica Neue', size:17),
    textColor: '#5481C9'.to_color;

  style :hours_drag_handle,
    # backgroundColor: UIColor.yellowColor,
    # alpha: 0.2,
    constraints: [
      constrain(:top).equals(:hours_indicator, :top).minus(DragHandleMargin),
      constrain(:bottom).equals(:hours_indicator, :bottom).plus(DragHandleMargin),
      constrain(:left).equals(:hours_indicator, :left).minus(DragHandleMargin),
      constrain(:right).equals(:hours_indicator, :right).plus(DragHandleMargin),
    ]

  style :hours_left_handle,
    # backgroundColor: UIColor.redColor,
    # alpha: 0.2,
    constraints: [
      constrain(:top).equals(:hours_indicator, :top).minus(DragHandleMargin),
      constrain(:bottom).equals(:hours_indicator, :bottom).plus(DragHandleMargin),
      constrain(:left).equals(:hours_indicator, :left).minus(DragHandleMargin),
      constrain(:right).equals(:hours_indicator, :left).plus(30),
    ]

  style :hours_right_handle,
    # backgroundColor: UIColor.blueColor,
    # alpha: 0.2,
    constraints: [
      constrain(:top).equals(:hours_indicator, :top).minus(DragHandleMargin),
      constrain(:bottom).equals(:hours_indicator, :bottom).plus(DragHandleMargin),
      constrain(:left).equals(:hours_indicator, :right).minus(30),
      constrain(:right).equals(:hours_indicator, :right).plus(DragHandleMargin),
    ];

  style :hours_left_handle_image,
    image: UIImage.imageNamed('images/hours-left-handle'),
    left: 4,
    top: 10,
    width: 6,
    height: 15;

  style :hours_right_handle_image,
    image: UIImage.imageNamed('images/hours-right-handle'),
    top: 17,
    constraints: [
      constrain(:right).equals(:superview, :right).minus(4)
    ];

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
    text: 'PM',
    textAlignment: NSTextAlignmentCenter,
    textColor: UIColor.whiteColor;

  style :hour_blob_half_past,
    left: 26,
    top: 13,
    width: 20,
    height: 20,
    font: font.fontWithSize(13),
    text: ':30',
    textAlignment: NSTextAlignmentRight,
    textColor: '#A8C1E5'.to_color;

  style :date,
    width: 320,
    height: 20,
    top: 5,
    font: font.fontWithSize(12);

  style :summary_hours,
    textAlignment: NSTextAlignmentCenter,
    textColor: UIColor.whiteColor,
    # TimeAnimationController#setMode sets the rest of the frame
    height: 30,
    alpha: 0;
end
