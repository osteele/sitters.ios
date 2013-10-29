class TimeSelectionController < UIViewController
  include BW::KVO

  # Semantics
  FirstHourNumber = 18
  Hours = FirstHourNumber..23
  MinHours = 1

  # Graphics and Animation
  AnimationDuration = 0.3
  DayFirstX = 3
  DaySpacing = 44
  HourFirstX = 10
  HourSpacing = 58
  ShortViewHeight = 55
  ShortViewTop = 64

  attr_accessor :timeSelection
  attr_accessor :delegate

  def initWithNibName(name, bundle:bundle)
    self
  end

  def viewDidLoad
    super
    self.view.stylename = :time_selector
    self.view.top = 20
    self.view.height = 120

    # do this here instead of initWithName so that views update to the time
    today = NSDate.date.dateAtStartOfDay
    self.timeSelection = TimeSelection.new(today, FirstHourNumber, FirstHourNumber + 3)
  end

  private

  attr_reader :interactiveModeOnlyViews
  attr_reader :summaryModeOnlyViews
  attr_reader :hoursSlider
  attr_reader :summaryViewHoursLabel

  layout do
    self.view.stylename = :time_selector

    @interactiveModeOnlyViews = []
    @summaryModeOnlyViews = []

    createDaySelectorViews
    createHourSelectorViews
  end

  def createDaySelectorViews
    firstDayOfDisplayedWeek = NSDate.date.dateAtStartOfDay
    dayLabelFormatter = dateFormatter('EEEE, MMMM d')
    dayLabel = subview UILabel, :date

    daySelectionMarker = nil
    daySelectionMarkerOffset = 5
    weekdayDates = (0...7).map do |day| firstDayOfDisplayedWeek.dateByAddingDays(day) end
    daySelectionMarker = subview UIView, :day_selection_marker do
      handle = subview UIView, width: 100, height: 100
      options = {
        xMinimum: DayFirstX + daySelectionMarkerOffset,
        xMaximum: DayFirstX + daySelectionMarkerOffset + (7 - 1) * DaySpacing,
        widthFactor: DaySpacing
      }
      TouchUtils.dragOnTouch handle.superview, handle:handle, options:options
      TouchUtils.bounceOnTap handle.superview, handle:handle
    end
    interactiveModeOnlyViews << daySelectionMarker
    @dayMarker = daySelectionMarker

    selectionMarkerLabels = []
    weekdayDates.each_with_index do |date, i|
      x = DayFirstX + i * DaySpacing
      name = NSDateFormatter.alloc.init.setDateFormat('EEEEE').stringFromDate(date)
      # Create a separate view for the selection marker label so that we can animate
      # the color transition. Animation animates opacity but not color.
      # A custom view could animate its text color, but the current system leaves
      # the possibility for a wider variety of transition effects in the future.
      label = subview UILabel, :day_of_week, left: x, text: name
      selectionMarkerLabel = subview UILabel, :day_of_week_overlay, left: x, text: name
      selectionMarkerLabel.userInteractionEnabled = false
      label.when_tapped do
        TestFlight.passCheckpoint "Tap day ###{i+1} (#{name})"
        self.timeSelection = timeSelection.onDate(date)
      end
      self.interactiveModeOnlyViews << label
      self.interactiveModeOnlyViews << selectionMarkerLabel
      selectionMarkerLabels << selectionMarkerLabel
    end

    daySelectionMarker.superview.bringSubviewToFront daySelectionMarker
    selectionMarkerLabels.each do |label| label.superview.bringSubviewToFront label end

    observe(daySelectionMarker, :frame) do
      selectionMarkerLabels.each do |label|
        dx = label.origin.x - daySelectionMarker.origin.x + daySelectionMarkerOffset
        label.alpha = 1 - [[dx.abs / 45.0, 1].min, 0].max
        dayIndex = ((daySelectionMarker.origin.x + daySelectionMarkerOffset - DayFirstX) / DaySpacing).round
        dayIndex = [[dayIndex, 0].max, weekdayDates.length - 1].min
        date = weekdayDates[dayIndex]
        self.timeSelection = timeSelection.onDate(date) unless timeSelection.date == date
      end
    end

    observe(self, :timeSelection) do |previousTimeSelection, timeSpan|
      unless previousTimeSelection and previousTimeSelection.date == timeSpan.date
        dayLabel.text = dayLabelFormatter.stringFromDate(timeSpan.date)
        currentWeekDayIndex = weekdayDates.index(timeSpan.date)
        selectedMarkerLabel = selectionMarkerLabels[currentWeekDayIndex]
        pos = CGPointMake(selectedMarkerLabel.x + daySelectionMarkerOffset, selectedMarkerLabel.y)
        daySelectionMarker.origin = pos if daySelectionMarker.top == 0 # first time
        UIView.animateWithDuration AnimationDuration, animations: -> { daySelectionMarker.x = pos.x }
      end
    end
  end

  def createHourSelectorViews
    hoursView = subview UIView do
      Hours.each_with_index do |hour, i|
        subview UIView, :hour_blob, left: HourFirstX + i * HourSpacing do
          # TODO use dateFormatter
          subview UILabel, :hour_blob_hour, text: (hour % 12).to_s
          subview UILabel, :hour_blob_am_pm
          subview UILabel, :hour_blob_half_past
        end
      end
    end
    interactiveModeOnlyViews << hoursView

    hourRangeLabel = nil
    @hoursSlider = subview UIView, :hour_slider do
      hourRangeLabel = subview UILabel, :hour_slider_label
      hourRangeLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth

      dragHandle = subview UIView, :hour_drag_handle
      leftDragHandle = subview UIView, :hour_left_handle do
        subview UIImageView, :hour_left_handle_image
      end
      rightDragHandle = subview UIView, :hour_right_handle do
        subview UIImageView, :hour_right_handle_image
      end

      target = leftDragHandle.superview
      dragOptions = {xMinimum: HourFirstX, widthMinimum: (MinHours + 0.5) * HourSpacing, widthFactor: HourSpacing / 2}
      TouchUtils.dragOnTouch target, handle:dragHandle, options:dragOptions
      TouchUtils.dragOnTouch target, handle:leftDragHandle, options:dragOptions.merge(resize:true)
      TouchUtils.resizeOnTouch target, handle:rightDragHandle, options:dragOptions
      [dragHandle, leftDragHandle, rightDragHandle].each do |handle|
        TouchUtils.bounceOnTap target, handle:handle
      end
    end

    @summaryViewHoursLabel = subview UILabel, :summaryHours

    interactiveModeOnlyViews << hoursSlider
    summaryModeOnlyViews << summaryViewHoursLabel

    # TODO use dateFormatter, to honor 24hr time. How to keep it from stripping the period?
    hourMinuteFormatter = NSDateFormatter.alloc.init.setDateFormat('h:mm')
    hourMinutePeriodFormatter = NSDateFormatter.alloc.init.setDateFormat('h:mma')
    periodFormatter = NSDateFormatter.alloc.init.setDateFormat('a')
    observe(self, :timeSelection) do |_, timeSpan|
      delegate.timeSelectionChanged timeSpan if delegate

      createHourRangeString = -> label, condensed=false {
        labelFont = hourRangeLabel.font
        boldFont = labelFont.fontWithSymbolicTraits(UIFontDescriptorTraitBold)
        boldFont = labelFont.fontWithSymbolicTraits(UIFontDescriptorTraitBold | UIFontDescriptorTraitCondensed) if condensed
        string = NSMutableAttributedString.alloc.initWithString(label)
        string.addAttribute NSFontAttributeName, value:boldFont, range:NSMakeRange(0, label.length)
        string.addAttribute NSFontAttributeName, value:labelFont.fontWithSize(8), range:NSMakeRange(label.length - 3, 1)
        string.addAttribute NSFontAttributeName, value:labelFont.fontWithSize(10), range:NSMakeRange(label.length - 2, 2)
        string
      }

      startPeriod = periodFormatter.stringFromDate(timeSpan.startTime)
      endPeriod = periodFormatter.stringFromDate(timeSpan.endTime)
      startFormatter = if startPeriod == endPeriod then hourMinuteFormatter else hourMinutePeriodFormatter end
      labelString = startFormatter.stringFromDate(timeSpan.startTime) + '-' + hourMinuteFormatter.stringFromDate(timeSpan.endTime) + ' ' + endPeriod

      labelAS = createHourRangeString.(labelString)
      summaryViewHoursLabel.attributedText = NSAttributedString.alloc.initWithAttributedString(labelAS)

      tooWide = -> { hoursSlider.size.width > 0 and labelAS.size.width > hoursSlider.size.width - hoursSlider.layer.cornerRadius }
      labelAS = createHourRangeString.(labelString.sub(/:00/, '')) if tooWide.()
      labelAS = createHourRangeString.(labelString.gsub(/:00/, '')) if tooWide.()
      labelAS = createHourRangeString.(labelString.gsub(/:00/, ''), true) if tooWide.()
      labelAS = createHourRangeString.(labelString.gsub(/:00/, '').gsub(/:30/, '½'), true) if tooWide.()
      hourRangeLabel.attributedText = NSAttributedString.alloc.initWithAttributedString(labelAS)
    end

    timeSpanHoursUpdater = Debounced.new 0.25 do
      summaryViewHoursLabel.frame = hoursSlider.frame
      startHour = FirstHourNumber + ((hoursSlider.left - HourFirstX) * 2 / HourSpacing).round / 2.0
      endHour = FirstHourNumber + ((hoursSlider.right - HourFirstX) * 2 / HourSpacing).round / 2.0 - 0.5
      startHour = [startHour, FirstHourNumber].max
      endHour = [endHour, startHour + MinHours].max
      self.timeSelection = timeSelection.betweenTimes(startHour, endHour)
    end

    observe(hoursSlider, :frame) do timeSpanHoursUpdater.fire! end
  end

  public

  def setMode(key, animated:animated)
    @timeSelectorHeightKey ||= :interactive
    return if @timeSelectorHeightKey == key

    @saveViewProperties ||= -> {
      saveFrameViews = [view, hoursSlider, summaryViewHoursLabel]
      saveAlphaViews = (interactiveModeOnlyViews + summaryModeOnlyViews)
      {
        alpha: saveAlphaViews.map { |v| [v, v.alpha] },
        frame: saveFrameViews.map { |v| [v, v.frame] }
      }
    }
    @restoreViewProperties ||= -> savedProperties {
      savedProperties[:alpha].each do |v, alpha| v.alpha = alpha end
      savedProperties[:frame].each do |v, frame| v.frame = frame end
    }

    if animated
      summaryViewHoursLabel.frame = hoursSlider.frame
      UIView.animateWithDuration AnimationDuration, animations: -> { setMode key, animated:false }
      return
    end

    @timeSelectorHeightKey = key
    view = self.view
    case key
    when :summary
      @savedTimeSelectorValues ||= @saveViewProperties.()
      view.top = ShortViewTop
      view.height = ShortViewHeight
      view.setNeedsDisplay
      interactiveModeOnlyViews.each do |v| v.alpha = 0 end
      summaryModeOnlyViews.each do |v| v.alpha = 1 end
      summaryViewHoursLabel.origin = [0, 18]
      summaryViewHoursLabel.width = 320
      hoursSlider.frame = summaryViewHoursLabel.frame
    when :interactive
      @restoreViewProperties.call @savedTimeSelectorValues
      @savedTimeSelectorValues = nil
    end
    gradient_layer = view.instance_variable_get(:@teacup_gradient_layer)
    gradient_layer.frame = view.bounds if gradient_layer
  end
end

class TimeSelection
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
    TimeSelection.new(date, startHour, endHour)
  end

  def betweenTimes(startHour, endHour)
    TimeSelection.new(date, startHour, endHour)
  end

  private

  def hourToTime(hour)
    date.dateByAddingHours(hour.floor).dateByAddingMinutes((hour * 60).floor % 60)
  end
end
