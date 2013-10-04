class SittersController < UIViewController
  layout do
    view.styleId = :sitters

    @scroll = subview UIScrollView.alloc.initWithFrame(self.view.bounds) do
      subview TimeSelector, styleId: :time_selector do
        now = Time.now
        now_label = subview UILabel, text: now.strftime('%A, %B %-e'), styleClass: :date

        day_highlighter = subview UIButton, styleClass: :selected_day

        x = 15
        overlays = []
        days = (0...7).map do |d| now + d * 24 * 3600 end
        days.each_with_index do |time, i|
          abbr = time.strftime('%A')[0]
          day_view = subview UILabel, text: abbr, styleClass: :day_of_week, left: x
          overlay = subview UILabel, text: abbr, styleClass: 'day_of_week overlay', left: x
          x += 44
          [day_view, overlay].each do |view|
            view.when_tapped do
              UIView.animateWithDuration 0.3,
                animations: lambda {
                  now_label.text = time.strftime('%A, %B %-e')
                  day_highlighter.origin = [day_view.origin[0] - 7, day_view.origin[1]]
                  overlays.map do |v| v.alpha = 0 end
                  overlay.alpha = 1
                }
              end
          end
          overlays << overlay
        end
        overlays.map do |v| v.alpha = 0 end
        overlays[0].alpha = 1

        [5, 6, 7, 8, 10, 11].each_with_index do |hour, i|
          subview UIView, styleClass: :hour_blob, left: 10 + i * 58 do
            subview UILabel, text: hour.to_s, styleClass: :hour
            subview UILabel, text: 'PM', styleClass: :am_pm
            subview UILabel, text: ':30', styleClass: :half_past
          end
        end

        subview UIButton, styleClass: :hour_range
        subview UILabel, text: '6:00—9:00PM', styleClass: :hour_range
      end

      cgMask = SitterCircle.maskImage

      subview UIView, styleId: :avatars do
        for i in 0...7
          sitter = Sitter.all[i]
          subview SitterCircle, origin: sitter_positions[i], dataSource: sitter, dataIndex: i, styleClass: 'sitter' do
            cgImage = sitter.image.CGImage
            cgImage = CGImageCreateWithMask(cgImage, cgMask)
            maskedImage = UIImage.imageWithCGImage(cgImage)
            subview UIImageView.alloc.initWithImage(maskedImage)
            subview UIButton
            subview UILabel, text: (i+1).to_s
          end
        end
      end

      subview UIButton, styleId: :recommended do
        subview UILabel, text: 'View Recommended'
        subview UILabel, styleClass: :caption, text: '14 connected sitters'
      end

      subview UIButton, left: 164, styleId: :invite do
        subview UILabel, text: 'Invite a Sitter'
        subview UILabel, styleClass: :caption, text: 'to add a sitter you know'
      end

      subview UILabel, styleId: :add_sitters, text: 'Add five more sitters'
      subview UILabel, styleId: :add_sitters_caption, text: 'to enjoy complete freedom and spontaneity.'
    end
  end

  def viewDidLoad
    super
    @scroll.frame = self.view.bounds
    @scroll.contentSize = CGSizeMake(@scroll.frame.size.width, @scroll.frame.size.height + 20)
  end

  def initWithNibName(name, bundle:bundle)
    super
    self.tap do
      self.tabBarItem = UITabBarItem.alloc.initWithTitle('Sitters', image:UIImage.imageNamed('tabs/sitters.png'), tag:1)
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
