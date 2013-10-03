class HomeController < UIViewController
  stylesheet :main

  layout :home do
    subview TimeSelector, :time_selector
    subview UILabel, :add_sitters
    subview UILabel, :add_sitters_caption
    for i in 0...7
      subview SitterCircle.new(Sitter.all[i]), { frame: circle_positions[i], backgroundColor: UIColor.blueColor }
    end
    # subview SquareButton.new("View Recommended", "14 connected sitters")
    # subview SquareButton.new("Invite a Sitter", "to add a sitter you know")
  end

  def circle_positions
    left = 80
    top = 153
    dx = 80
    dy = 80
    [
      CGRectMake(left, top, 80, 80),
      CGRectMake(left + dx, top, 80, 80),
      CGRectMake(left - 80/2, top + dy, 80, 80),
      CGRectMake(left - 80/2 + dx, top + dy, 80, 80),
      CGRectMake(left - 80/2 + 2 * dx, top + dy, 80, 80),
      CGRectMake(left, top + 2 * dy, 80, 80),
      CGRectMake(left + dx, top + 2 * dy, 80, 80),
    ]
  end
end
