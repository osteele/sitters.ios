class SittersController < UIViewController
  include BW::KVO

  attr_accessor :selectedTimespan

  def initWithNibName(name, bundle:bundle)
    super
    self.tap do
      self.tabBarItem = UITabBarItem.alloc.initWithTitle('Sitters', image:UIImage.imageNamed('tabs/sitters.png'), tag:1)
    end
  end

  def viewDidLoad
    super
    @scroll.frame = self.view.bounds
    @scroll.contentSize = CGSizeMake(@scroll.frame.size.width, @scroll.frame.size.height + 20)

    today = NSDate.date.dateAtStartOfDay
    self.selectedTimespan = Timespan.new(today)
  end

  layout do
    view.styleId = :sitters

    @scroll = subview UIScrollView.alloc.initWithFrame(self.view.bounds) do
      createTimeSelector
      createSitterAvatars

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

  private

  def createTimeSelector
    weekStartDay = NSDate.date.dateAtStartOfDay

    subview TimeSelector, styleId: :time_selector do
      dayLabelFormatter = NSDateFormatter.alloc.init.setDateFormat('EEEE, MMMM d')
      dayLabel = subview UILabel, styleClass: :date

      dayHighlighter = subview UIButton, styleClass: :selected_day

      overlays = []
      weekDayTimes = (0...7).map do |d| weekStartDay.dateByAddingDays(d) end
      weekDayTimes.each_with_index do |time, i|
        x = 3 + i * 44
        name = NSDateFormatter.alloc.init.setDateFormat('EEEEE').stringFromDate(time)
        label = subview UILabel, text: name, styleClass: :day_of_week, left: x
        overlay = subview UILabel, text: name, styleClass: 'day_of_week overlay', left: x
        [label, overlay].each do |view|
          view.when_tapped do
            TestFlight.passCheckpoint "Tap day: #{name}"
            self.selectedTimespan = Timespan.new(time)
          end
        end
        overlays << overlay
      end

      observe(self, :selectedTimespan) do |_, value|
        dayLabel.text = dayLabelFormatter.stringFromDate(value.endTime)
        currentWeekDayIndex = weekDayTimes.index(value.endTime)
        selectedOverlay = overlays[currentWeekDayIndex]
        UIView.animateWithDuration 0.3,
          animations: lambda {
            dayHighlighter.origin = [selectedOverlay.origin[0] + 5, selectedOverlay.origin[1]]
            overlays.map do |v| v.alpha = 0 end
            selectedOverlay.alpha = 1
          }
      end

      [5, 6, 7, 8, 10, 11].each_with_index do |hour, i|
        subview UIView, styleClass: :hour_blob, left: 10 + i * 58 do
          subview UILabel, text: hour.to_s, styleClass: :hour
          subview UILabel, text: 'PM', styleClass: :am_pm
          subview UILabel, text: ':30', styleClass: :half_past
        end
      end

      range_button = subview UIButton, styleClass: :hour_range
      range_label = subview UILabel, text: '6:00—9:00PM', styleClass: :hour_range
      range_button.when_tapped { TestFlight.passCheckpoint "Tap hour range: ##{i+1}" }
      range_label.when_tapped { TestFlight.passCheckpoint "Tap hour range: ##{i+1}" }
    end
  end

  def createSitterAvatars
    cgMask = SitterCircle.maskImage

    sitterViews = []
    subview UIView, styleId: :avatars do
      for i in 0...7
        sitter = Sitter.all[i]
        view = subview SitterCircle, origin: sitter_positions[i], dataSource: sitter, dataIndex: i, styleClass: 'sitter' do
          cgImage = sitter.image.CGImage
          cgImage = CGImageCreateWithMask(cgImage, cgMask)
          maskedImage = UIImage.imageWithCGImage(cgImage)
          subview UIImageView.alloc.initWithImage(maskedImage)
          subview UIButton
          subview UILabel, text: (i+1).to_s
        end
        view.when_tapped { TestFlight.passCheckpoint "Tap sitter: ##{i+1}" }
        sitterViews << view
      end
    end

    observe(self, :selectedTimespan) do |_, value|
      time = value.endTime
      UIView.animateWithDuration 0.3,
        animations: lambda {
          sitterViews.map do |view|
            view.alpha = if view.dataSource.availableAt(time) then 1 else 0.5 end
          end
        }
      end
  end

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

class Timespan
  attr_reader :beginTime, :endTime

  def initialize(beginTime, endTime=nil)
    @beginTime = beginTime
    @endTime = endTime || beginTime
  end
end
