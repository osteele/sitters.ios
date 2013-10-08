class SittersController < UIViewController
  include BW::KVO
  stylesheet :sitters

  attr_accessor :selectedTimeSpan

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
    self.selectedTimeSpan = TimeSpan.new(today, 18, 21)
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
            # self.selectedTimeSpan = TimeSpan.new(date, selectedTimeSpan.startHour, selectedTimeSpan.endHour)
            self.selectedTimeSpan = selectedTimeSpan.onDate(date)
          end
        end
        overlays << overlay
      end

      observe(self, :selectedTimeSpan) do |previousTimeSpan, timeSpan|
        # return if previousTimeSpan and previousTimeSpan.date == timeSpan.date
        dayLabel.text = dayLabelFormatter.stringFromDate(timeSpan.date)
        currentWeekDayIndex = weekdayDates.index(timeSpan.date)
        selectedOverlay = overlays[currentWeekDayIndex]
        UIView.animateWithDuration 0.3,
          animations: lambda {
            dayHighlighter.origin = [selectedOverlay.origin[0] + 5, selectedOverlay.origin[1]]
            overlays.map do |v| v.alpha = 0 unless v == selectedOverlay end
            selectedOverlay.alpha = 1
          }
      end

      firstHourOffset = 10
      firstHourNumber = 18
      hourWidth = 58
      [6, 7, 8, 9, 10, 11].each_with_index do |hour, i|
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

        left_dragger = subview UIView, :left_dragger, styleClass: :left_dragger, styleId: :left_dragger do
          subview UIView, styleClass: :graphic
        end
        right_dragger = subview UIView, :right_dragger, styleClass: :right_dragger, styleId: :right_dragger do
          subview UIView, styleClass: :graphic
        end
        addDragger left_dragger, min: firstHourOffset, factor: hourWidth / 2
        addResizer right_dragger, min_width: minHours * hourWidth, factor: hourWidth / 2
      end

      # TODO use dateFormatter, to honor 24hr time. How to keep it from stripping the period?
      hourMinuteFormatter = NSDateFormatter.alloc.init.setDateFormat('h:mm')
      hourMinutePeriodFormatter = NSDateFormatter.alloc.init.setDateFormat('h:mma')
      periodFormatter = NSDateFormatter.alloc.init.setDateFormat('a')
      observe(self, :selectedTimeSpan) do |_, timeSpan|
        startPeriod = periodFormatter.stringFromDate(timeSpan.startTime)
        endPeriod = periodFormatter.stringFromDate(timeSpan.endTime)
        startFormatter = if startPeriod == endPeriod then hourMinuteFormatter else hourMinutePeriodFormatter end
        label = startFormatter.stringFromDate(timeSpan.startTime) + '-' + hourMinuteFormatter.stringFromDate(timeSpan.endTime) + ' ' + endPeriod
        string = NSMutableAttributedString.alloc.initWithString(label)
        fontName = "HelveticaNeue"
        string.addAttribute NSFontAttributeName, value:UIFont.fontWithName(fontName + "-Bold", size:15), range:NSMakeRange(0, label.length)
        string.addAttribute NSFontAttributeName, value:UIFont.fontWithName(fontName, size:8), range:NSMakeRange(label.length - 3, 1)
        string.addAttribute NSFontAttributeName, value:UIFont.fontWithName(fontName, size:10), range:NSMakeRange(label.length - 2, 2)
        range_label.attributedText = string
      end

      updater = Debounced.new 0.5 do
        frame = range_button.frame
        startHour = firstHourNumber + ((range_button.origin.x - firstHourOffset) / hourWidth * 2).round / 2.0
        endHour = firstHourNumber + ((range_button.origin.x + range_button.size.width - firstHourOffset) / hourWidth * 2).round / 2.0 - 0.5
        startHour = [startHour, firstHourNumber].max
        endHour = [endHour, startHour + minHours].max
        self.selectedTimeSpan = selectedTimeSpan.betweenTimes(startHour, endHour)
      end

      observe(range_button, :frame) do |_, frame|
        updater.fire!
      end
    end
  end

  def addDragger(dragger, options={})
    # class << dragger
    #   def target; self.superview; end

    #   def touchesBegan(touches, withEvent:event)
    #     @initialOrigin = target.origin
    #     @initialTouchPoint = touches.anyObject.locationInView(target.superview)
    #   end

    #   def touchesMoved(touches, withEvent:event)
    #     touchPoint = touches.anyObject.locationInView(target.superview)
    #     offset = CGPoint.new(touchPoint.x - @initialTouchPoint.x, touchPoint.y - @initialTouchPoint.y)
    #     target.origin = [[0, @initialOrigin.x + offset.x].max, target.origin.y]
    #   end
    # end
    # return

    target = dragger.superview
    initial = nil
    dragger.userInteractionEnabled = true
    dragger.when_panned do |recognizer|
      pt = recognizer.translationInView(target.superview)
      case recognizer.state
      when UIGestureRecognizerStateBegan
        initial = target.origin
      when UIGestureRecognizerStateChanged
        target.origin = [[initial.x + pt.x, options[:min] || 0].max, target.origin.y]
      when UIGestureRecognizerStateEnded
        min = options[:min] || 0
        factor = options[:factor] || 1
        x = ((target.origin.x - min) / factor).round * factor + min
        UIView.animateWithDuration 0.1,
          animations: lambda {
            target.origin = [[x, options[:min] || 0].max, target.origin.y]
          }
      end
    end
  end

  def addResizer(dragger, options={})
    # class << dragger
    #   def target; self.superview; end

    #   def touchesBegan(touches, withEvent:event)
    #     @initialSize = target.size
    #     @initialTouchPoint = touches.anyObject.locationInView(target.superview)
    #   end

    #   def touchesMoved(touches, withEvent:event)
    #     touchPoint = touches.anyObject.locationInView(target.superview)
    #     offset = CGPoint.new(touchPoint.x - @initialTouchPoint.x, touchPoint.y - @initialTouchPoint.y)
    #     target.size = [[@initialSize.width + offset.x, 100].max, target.size.height]
    #     self.origin = [target.size.width - self.size.width, self.origin.y]
    #   end
    # end
    # return

    dragger.userInteractionEnabled = true
    target = dragger.superview
    initial = nil
    fudge = 21
    dragger.when_panned do |recognizer|
      pt = recognizer.translationInView(target.superview)
      case recognizer.state
      when UIGestureRecognizerStateBegan
        initial = target.size
      when UIGestureRecognizerStateChanged
        target.size = [[initial.width + pt.x, options[:min_width] || 0].max, target.size.height]
        dragger.origin = [target.size.width - dragger.size.width + fudge, dragger.origin.y]
      when UIGestureRecognizerStateEnded
        factor = options[:factor] || 1
        width = (target.size.width / factor).round * factor
        UIView.animateWithDuration 0.1,
          animations: lambda {
            target.size = [[width, options[:min_width] || 0].max, target.size.height]
            dragger.origin = [target.size.width - dragger.size.width + fudge, dragger.origin.y]
          }
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
        sitter.active = true
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

    observe(self, :selectedTimeSpan) do |_, timeSpan|
      UIView.animateWithDuration 0.3,
        animations: lambda {
          sitterViews.map do |view|
            alpha = if view.dataSource.availableAt(timeSpan) then 1 else 0.5 end
            view.alpha = alpha unless view.alpha == alpha
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
      [0, 0], [1, 0],
      [0, 1], [1, 1], [2, 1],
      [0, 2], [1, 2],
    ].map do |x, y|
      left = (if y == 1 then left2 else left1 end)
      [left + x * width, top + y * height]
    end
  end
end

class TimeSpan
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
    TimeSpan.new(date, startHour, endHour)
  end

  def betweenTimes(startHour, endHour)
    TimeSpan.new(date, startHour, endHour)
  end

  private

  def hourToTime(hour)
    date.dateByAddingHours(hour.floor).dateByAddingMinutes((hour * 60).floor % 60)
  end
end

Teacup::Stylesheet.new :sitters do
  style :sitters,
    backgroundColor: UIColor.greenColor

  # style :left_dragger,
  #   backgroundColor: UIColor.greenColor

  style :right_dragger,
    # backgroundColor: UIColor.blueColor,
    left: '100%-20',
    top: 0,
    width: 40,
    height: '100%'
end

class Scheduler
  attr_reader :pending

  def self.after(delay, &block)
    self.new.after(delay, &block)
  end

  def after(delay, &block)
    @block = block
    @timer = NSTimer.scheduledTimerWithTimeInterval(delay, target:self, selector:'fire', userInfo:nil, repeats:false)
    @pending = true
    return self
  end

  def fire
    @pending = false
    @block.call
  end
end

class Debounced
  def initialize(delay, &block)
    @delay = delay
    @block = block
    @scheduler = Scheduler.new
  end

  def fire!
    return if @scheduler.pending
    @scheduler.after @delay, &@block
  end
end
