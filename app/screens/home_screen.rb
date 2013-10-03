class HomeScreen < PM::Screen
  include HomeStyles
  title "Home"

  def on_load
    # set_nav_bar_button :left, title: "Help", action: :help_tapped
    # set_nav_bar_button :right, title: "Sitters", action: :sitters_tapped
    set_attributes self.view, { background_color: hex_color("F9F9F9") }

    add TimeSelectionView.new, { frame: CGRectMake(0, 20, 320, 120) }

    for i in 0...7
      add SitterCircle.new(Sitter.all[i]), { frame: circle_positions[i] }
    end

    # add SitterItem.new, { frame: CGRectMake( 20,  40, 130, 130) }
    # add SitterItem.new, { frame: CGRectMake(170,  40, 130, 130) }
    # add SitterItem.new, { frame: CGRectMake( 20, 190, 130, 130) }
    # add SitterItem.new, { frame: CGRectMake(170, 190, 130, 130) }
    # add SitterItem.new, { frame: CGRectMake( 20, 340, 130, 130) }
    # add SitterItem.new, { frame: CGRectMake(170, 340, 130, 130) }

    add UILabel.new, add_sitters_label_view
    add UILabel.new, add_sitters_label_caption_view
    add SquareButton.new("View Recommended", "14 connected sitters")
    add SquareButton.new("Invite a Sitter", "to add a sitter you know")

    # toolbar: Sitters, Search, Updates, Chat, Settings
  end

  def circle_positions
    top = 160 - 7
    dy = 100 - 22 + 13
    [
      CGRectMake( 82, top, 80, 80),
      CGRectMake(172, top, 80, 80),
      CGRectMake( 40, top + dy, 80, 80),
      CGRectMake(126, top + dy, 80, 80),
      CGRectMake(210, top + dy, 80, 80),
      CGRectMake( 82, top + 2 * dy, 80, 80),
      CGRectMake(172, top + 2 * dy, 80, 80),
    ]
  end

  def on_present
    @view_setup ||= self.set_up_view
  end

  # def set_up_view
  #   true
  # end

  # def sitters_tapped
  #   open SittersScreen
  # end

  # def help_tapped
  #   open_modal HelpScreen.new(nav_bar: true)
  # end
end
