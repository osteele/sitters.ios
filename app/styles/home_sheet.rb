Teacup::Stylesheet.new :main do
  style :home,
    backgroundColor: "#F9F9F9".uicolor

  style :time_selector,
    origin: [0, 20],
    width: 320,
    height: 120,
    backgroundColor: "#5582C3".uicolor

  style :sitter,
    width: 80,
    height: 80,
    backgroundColor: UIColor.blueColor

  style :add_sitters,
    text: "Add five more sitters",
    textColor: "#5481C9".uicolor,
    textAlignment: UITextAlignmentCenter,
    font: UIFont.systemFontOfSize(13.0),
    origin: [10, 405],
    width: 300,
    height: 45

  style :add_sitters_caption,
    text: "to enjoy complete freedom and spontaneity.",
    textColor: "#969696".uicolor,
    textAlignment: UITextAlignmentCenter,
    font: UIFont.systemFontOfSize(12.0),
    origin: [10, 415],
    width: 300,
    height: 45

  style UILabel,
    textColor: UIColor.blueColor
end
