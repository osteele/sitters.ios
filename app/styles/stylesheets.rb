Teacup::Stylesheet.new :sitters do
  style :time_selector,
    # top: 20,
    # width: 320
    # height: 120
    gradient:  { colors: [0x6FA1EB.uicolor, 0x4E7EC2.uicolor] }

  style :hours_bar,
    backgroundColor: UIColor.whiteColor,
    left: 10,
    top: 75;

  style :right_dragger,
    left: '100%-20',
    top: 0,
    width: 40,
    height: '100%'
end
