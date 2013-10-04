class SittersController < UIViewController
  stylesheet :sitters

  layout :root do
    subview UIScrollView, :scroll_view do
      subview TimeSelector, styleId: 'time_selector'

      subview UIView, styleId: 'avatars' do
        for i in 0...7
          subview SitterCircle, origin: sitter_positions[i], dataSource: Sitter.all[i], dataIndex: i, styleClass: 'sitter' do
            subview UILabel, text: (i+1).to_s
          end
        end
      end

      subview UIButton, styleId: 'recommended' do
        subview UILabel, text: 'View Recommended'
        subview UILabel, text: '14 connected sitters', styleClass: 'caption'
      end

      subview UIButton, left: 164, styleId: 'invite' do
        subview UILabel, text: 'Invite a Sitter'
        subview UILabel, text: 'to add a sitter you know', styleClass: 'caption'
      end

      subview UILabel, styleId: 'add_sitters', text: 'Add five more sitters'
      subview UILabel, styleId: 'add_sitters_caption', text: 'to enjoy complete freedom and spontaneity.'
    end
  end

  def initWithNibName(name, bundle:bundle)
    super
    self.tap do
      self.tabBarItem = UITabBarItem.alloc.initWithTitle('Sitters', image:UIImage.imageNamed('sitters.png'), tag:1)
      view.styleId = 'sitters'
    end
  end

  private

  def sitter_positions
    top = 0
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
