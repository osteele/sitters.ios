class HomeController < UIViewController
  stylesheet :main

  layout :home do
    subview TimeSelector, :time_selector
    subview UILabel, :add_sitters
    subview UILabel, :add_sitters_caption
    for i in 0...7
      subview SitterCircle.new(i, Sitter.all[i]), :sitter, { frame: circle_positions[i] }
    end

    subview UIView, :home_square, :recommended_square do
      subview UILabel, :square_label, :view_recommended
      subview UILabel, :square_caption, :recommended_caption
    end

    subview UIView, :home_square, :invite_square do
      subview UILabel, :square_label, :invite
      subview UILabel, :square_caption, :invite_caption
    end
  end

  def circle_positions
    left1 = 60
    left2 = 108 - 96
    top = 153
    dx = 96
    dy = 84
    side = 90
    [
      CGRectMake(left1, top, side, side),
      CGRectMake(left1 + dx, top, side, 80),
      CGRectMake(left2, top + dy, side, side),
      CGRectMake(left2 + dx, top + dy, side, side),
      CGRectMake(left2 + 2 * dx, top + dy, side, side),
      CGRectMake(left1, top + 2 * dy, side, side),
      CGRectMake(left1 + dx, top + 2 * dy, side, side),
    ]
  end
end
