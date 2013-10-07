class SittersController < UIViewController
  include BW::KVO
  stylesheet :sitters

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

    self.view.stylesheet = :sitters
    self.view.stylename = :sitters

    today = NSDate.date.dateAtStartOfDay
    self.selectedTimespan = Timespan.new(today, 18, 21)
  end

  layout do
    view.styleId = :sitters

    @scroll = subview UIScrollView.alloc.initWithFrame(self.view.bounds) do
      createTimeSelector
      createSitterAvatars

      subview UIButton, styleId: :recommended, styleClass: :big_button do
        subview UILabel, text: 'View Recommended'
        subview UILabel, styleClass: :caption, text: '14 connected sitters'
      end

      subview UIButton, styleId: :invite, styleClass: :big_button do #left: 164,
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
      dayLabelFormatter = dateFormatter('EEEE, MMMM d')
      dayLabel = subview UILabel, styleClass: :date

      dayHighlighter = subview UIButton, styleClass: :selected_day

      overlays = []
      weekdayDates = (0...7).map do |day| weekStartDay.dateByAddingDays(day) end
      weekdayDates.each_with_index do |date, i|
        x = 3 + i * 44
        name = NSDateFormatter.alloc.init.setDateFormat('EEEEE').stringFromDate(date)
        label = subview UILabel, text: name, styleClass: :day_of_week, left: x
        overlay = subview UILabel, text: name, styleClass: 'day_of_week overlay', left: x
        [label, overlay].each do |view|
          view.when_tapped do
            TestFlight.passCheckpoint "Tap day: #{name}"
            # self.selectedTimespan = Timespan.new(date, selectedTimespan.startHour, selectedTimespan.endHour)
            self.selectedTimespan = selectedTimespan.onDate(date)
          end
        end
        overlays << overlay
      end

      observe(self, :selectedTimespan) do |previousTimespan, timespan|
        # return if previousTimespan and previousTimespan.date == timespan.date
        dayLabel.text = dayLabelFormatter.stringFromDate(timespan.date)
        currentWeekDayIndex = weekdayDates.index(timespan.date)
        selectedOverlay = overlays[currentWeekDayIndex]
        UIView.animateWithDuration 0.3,
          animations: lambda {
            dayHighlighter.origin = [selectedOverlay.origin[0] + 5, selectedOverlay.origin[1]]
            overlays.map do |v| v.alpha = 0 unless v == selectedOverlay end
            selectedOverlay.alpha = 1
          }
      end

      firstHourOffset = 10
      firstHourNumber = 17
      hourWidth = 58
      [5, 6, 7, 8, 10, 11].each_with_index do |hour, i|
        subview UIView, styleClass: :hour_blob, left: 10 + i * 58 do
          # TODO use dateFormatter
          subview UILabel, text: hour.to_s, styleClass: :hour
          subview UILabel, text: 'PM', styleClass: :am_pm
          subview UILabel, text: ':30', styleClass: :half_past
        end
      end

      minHours = 2
      range_label = nil
      range_button = subview UIButton, styleClass: :hour_range, styleId: :hour_range do
        range_label = subview UILabel, styleClass: :hour_range
        range_label.autoresizingMask = UIViewAutoresizingFlexibleWidth

        left_dragger = subview UIView, :left_dragger, styleClass: :left_dragger, styleId: :left_dragger
        right_dragger = subview UIView, :right_dragger, styleClass: :right_dragger, styleId: :right_dragger
        addDragger left_dragger
        addResizer right_dragger, min_width: minHours * hourWidth
      end

      # TODO use dateFormatter, to honor 24hr time. How to keep it from stripping the period?
      hourMinuteFormatter = NSDateFormatter.alloc.init.setDateFormat('HH:mm')
      hourMinutePeriodFormatter = NSDateFormatter.alloc.init.setDateFormat('HH:mma')
      periodFormatter = NSDateFormatter.alloc.init.setDateFormat('a')
      observe(self, :selectedTimespan) do |_, timespan|
        startPeriod = periodFormatter.stringFromDate(timespan.startTime)
        endPeriod = periodFormatter.stringFromDate(timespan.endTime)
        startFormatter = if startPeriod == endPeriod then hourMinuteFormatter else hourMinutePeriodFormatter end
        label = startFormatter.stringFromDate(timespan.startTime) + '–' + hourMinutePeriodFormatter.stringFromDate(timespan.endTime)
        range_label.text = label
      end

      observe(range_button, :frame) do |_, frame|
        frame = range_button.frame # the argument is an opaque value
        startHour = firstHourNumber + ((range_button.origin.x - firstHourOffset) / hourWidth * 2).floor / 2.0
        endHour = firstHourNumber + ((range_button.origin.x + range_button.size.width - firstHourOffset) / hourWidth * 2).floor / 2.0
        startHour = [startHour, firstHourNumber].max
        endHour = [endHour, startHour + minHours].max
        self.selectedTimespan = selectedTimespan.betweenTimes(startHour, endHour)
      end
    end
  end

  def addDragger(dragger)
    target = dragger.superview
    initial = nil
    dragger.when_panned do |recognizer|
      pt = recognizer.translationInView(target.superview)
      case recognizer.state
      when UIGestureRecognizerStateBegan
        initial = target.origin
      when UIGestureRecognizerStateChanged
        target.origin = [[0, initial.x + pt.x].max, target.origin.y]
      end
    end
  end

  def addResizer(dragger, options={})
    target = dragger.superview
    initial = nil
    dragger.when_panned do |recognizer|
      pt = recognizer.translationInView(target.superview)
      case recognizer.state
      when UIGestureRecognizerStateBegan
        initial = target.size
      when UIGestureRecognizerStateChanged
        target.size = [[initial.width + pt.x, options[:min_width] || 0].max, target.size.height]
        dragger.origin = [target.size.width - dragger.size.width, dragger.origin.y]
      end
    end
  end

  def dateFormatter(template)
    template = NSDateFormatter.dateFormatFromTemplate(template, options:0, locale:NSLocale.currentLocale)
    dayLabelFormatter = NSDateFormatter.alloc.init.setDateFormat(template)
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
      time = value.date
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
  attr_reader :date, :startHour, :endHour

  def initialize(date, startHour, endHour)
    @date = date
    @startHour = startHour
    @endHour = endHour
  end

  def startTime
    hourToTime(startHour)
  end

  def endTime
    hourToTime(endHour)
  end

  def onDate(date)
    Timespan.new(date, startHour, endHour)
  end

  def betweenTimes(startHour, endHour)
    Timespan.new(date, startHour, endHour)
  end

  private

  def hourToTime(hour)
    date.dateByAddingHours(hour.floor).dateByAddingMinutes((hour * 60).floor % 60)
  end
end

Teacup::Stylesheet.new :sitters do
  # style :left_dragger,
  #   backgroundColor: UIColor.greenColor

  style :right_dragger,
    # backgroundColor: UIColor.blueColor,
    left: '100%-20',
    top: 0,
    width: 20,
    height: '100%'
end
