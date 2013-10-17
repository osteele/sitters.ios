Teacup::Stylesheet.new :booking do
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

  style :hours_bar,
    backgroundColor: UIColor.whiteColor,
    left: 10,
    top: 75

  style :right_dragger,
    left: '100%-20',
    top: 0,
    width: 40,
    height: 35

  style :right_drag_graphic,
    width: 6,
    height: 15,
    top: 10,
    left: 9,
    image: UIImage.imageNamed('images/right-drag-handle')
end
