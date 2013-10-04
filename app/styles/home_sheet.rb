Teacup::Stylesheet.new :main do
  style :home,
    backgroundColor: "#F9F9F9".uicolor

  style :time_selector,
    origin: [0, 20],
    width: 320,
    height: 120,
    backgroundColor: "#5582C3".uicolor

  style :sitter,
    width: 90,
    height: 90,
    backgroundColor: UIColor.clearColor


  style :recommended_square,
    origin: [5, 450],
    width: 150,
    height: 45,
    backgroundColor: "#5582C3".uicolor

  style :view_recommended,
    origin: [0, -10],
    width: 150,
    height: 50,
    font: UIFont.systemFontOfSize(14.0),
    textAlignment: UITextAlignmentCenter,
    textColor: UIColor.whiteColor,
    text: "View Recommended"

  style :recommended_caption,
    origin: [0, 2],
    width: 150,
    height: 50,
    font: UIFont.systemFontOfSize(10.0),
    textAlignment: UITextAlignmentCenter,
    textColor: UIColor.whiteColor,
    text: "14 connected sitters"


  style :invite_square,
    origin: [164, 450],
    width: 150,
    height: 45,
    backgroundColor: "#A6A6A6".uicolor

  style :invite,
    origin: [0, -10],
    width: 150,
    height: 50,
    font: UIFont.systemFontOfSize(14.0),
    textAlignment: UITextAlignmentCenter,
    textColor: UIColor.whiteColor,
    text: "Invite a Sitter"

  style :invite_caption,
    origin: [0, 2],
    width: 150,
    height: 50,
    font: UIFont.systemFontOfSize(10.0),
    textAlignment: UITextAlignmentCenter,
    textColor: UIColor.whiteColor,
    text: "to add a sitter you know"


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
