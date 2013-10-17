Teacup::Stylesheet.new :booking do
  style :time_selector,
  top: 20,
  width: 320,
  height: 120

  style UILabel,
    textColor: UIColor.whiteColor,
    textAlignment: NSTextAlignmentCenter

  style :day_of_week,
    width: 44,
    height: 34,
    top: 30,
    font: UIFont.fontWithName('Helvetica', size:18)

  style :day_of_week_overlay,
    width: 44,
    height: 34,
    top: 30,
    font: UIFont.fontWithName('Helvetica', size:18),
    textColor: 0x5481C9.uicolor

  style :day_selection_marker,
    left: 8,
    top: 30,
    width: 34,
    height: 34,
    backgroundColor: UIColor.whiteColor

  style :hour_slider,
    left: 10,
    top: 75,
    width: 195,
    height: 35,
    backgroundColor: UIColor.whiteColor,
    textColor: 0x5481C9.uicolor

  style :hour_slider_label,
    width: 195,
    height: 35,
    textColor: 0x5481C9.uicolor

  style :hour_left_handle,
      left: 0,
      top: 0,
      width: 640,
      height: 35

  style :hour_right_handle,
    left: '100%-20',
    top: 0,
    width: 40,
    height: 35
    # constraints: [
    #   # constrain_width(100),
    #   # pin to bottom-right corner
    #   constrain(:right).equals(:superview, :right)
    # ]

  style :hour_left_handle_image,
    image: UIImage.imageNamed('images/left-drag-handle'),
    left: 4,
    top: 10,
    width: 6,
    height: 15

  style :hour_right_handle_image,
    width: 6,
    height: 15,
    top: 10,
    left: 9,
    image: UIImage.imageNamed('images/right-drag-handle')

  style :hour_blob,
    top: 70,
    width: 40,
    height: 40

  style :hour_blog_hour,
    top: 8,
    width: 20,
    height: 20,
    font: UIFont.fontWithName('Helvetica', size:14),
    textAlignment: NSTextAlignmentCenter;

  style :hour_blog_am_pm,
    top: 20,
    width: 20,
    height: 20,
    font: UIFont.fontWithName('Helvetica', size:9),
    textAlignment: NSTextAlignmentCenter;

  style :hour_blog_half_past,
    left: 26,
    top: 13,
    width: 20,
    height: 20,
    textColor: 0xA8C1E5.uicolor,
    font: UIFont.fontWithName('Helvetica', size:13),
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
    font: UIFont.fontWithName('Helvetica', size:12)
end
