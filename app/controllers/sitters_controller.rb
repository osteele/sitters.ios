class SittersController < UIViewController
  stylesheet :sitters

  layout :sitters do
    subview TimeSelector, :time_selector
    subview UILabel, :add_sitters
    subview UILabel, :add_sitters_caption
    for i in 0...7
      subview SitterCircle, :sitter, { origin: circle_positions[i], dataSource: Sitter.all[i], dataIndex: i }
    end

    subview UIButton, :home_square, :recommended_square do
      subview UILabel, :square_label, :big_button_label, { text: 'View Recommended' }
      subview UILabel, :square_caption, :big_button_caption, { text: '14 connected sitters' }
    end

    subview UIButton, :home_square, :invite_square do
      subview UILabel, :square_label, :big_button_label, { text: 'Invite a Sitter' }
      subview UILabel, :square_caption, :big_button_caption, { text: 'to add a sitter you know' }
    end
  end

  def initWithNibName(name, bundle:bundle)
    super
    self.tabBarItem = UITabBarItem.alloc.initWithTitle('Sitters', image:UIImage.imageNamed('sitters.png'), tag:1)
    self
  end

  def circle_positions
    top = 153
    left1 = 70
    left2 = left1 - 48
    width = 96
    height = 84
    [
      [0, 0],
      [1, 0],
      [0, 1],
      [1, 1],
      [2, 1],
      [0, 2],
      [1, 2],
    ].map do |x, y|
      left = (if y == 1 then left2 else left1 end)
      [left + x * width, top + y * height]
    end
  end
end
