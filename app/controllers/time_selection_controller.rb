class TimeSelectionController < UIViewController
  include BW::KVO

  # Semantics
  FirstHourNumber = 18
  Hours = FirstHourNumber..23
  MinHours = 1

  # Layout and Animation
  DayIndicatorAnimationSeconds = 0.3
  DayFirstX = 3
  DayIndicatorOffset = 5
  DaySpacing = 44
  HourFirstX = 10
  HourSpacing = 58

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

  # animation modifies these views
  attr_reader :dayIndicator
  attr_reader :hoursIndicator
  attr_reader :hourRangeLabel
  attr_reader :summaryViewHoursLabel
  attr_reader :summaryViewHoursLabelFg


  #
  # Views and observer creation
  #

  layout do
    self.view.stylename = :time_selector
    createDaySelectionViews
    createHourSelectionViews
  end

  def createDaySelectionViews
    firstDayOfDisplayedWeek = NSDate.date.dateAtStartOfDay
    dayLabelFormatter = dateFormatter('EEEE, MMMM d')
    dayLabel = subview UILabel, :date

    weekdayDates = (0...7).map { |day| firstDayOfDisplayedWeek.dateByAddingDays(day) }
    @dayIndicator = subview UIView, :day_indicator
    declareViewMode :interactive, dayIndicator
    dayIndicatorHandle = subview(UIView, :day_indicator_handle).tap do |handle|
      options = {
        xMinimum: DayFirstX + DayIndicatorOffset,
        xMaximum: DayFirstX + DayIndicatorOffset + (7 - 1) * DaySpacing,
        widthFactor: DaySpacing
      }
      TouchUtils.dragOnTouch dayIndicator, handle:handle, options:options
      TouchUtils.bounceOnTap dayIndicator, handle:handle
      # registerTouchEffectHandle handle, target:dayIndicator
    end

    selectionMarkerLabels = []
    weekdayFormatter = NSDateFormatter.alloc.init.setDateFormat('EEEEE')
    weekdayDates.each_with_index do |date, i|
      x = DayFirstX + i * DaySpacing
      # Jump to the *middle* of the day to work around `dateByAddingDays` bug around DST
      name = weekdayFormatter.stringFromDate(date.dateByAddingHours(12))
      # Create a separate view for the selection marker label so that we can animate
      # the color transition. Animation animates opacity but not color.
      # A custom view could animate its text color, but the current system leaves
      # the possibility for a wider variety of transition effects in the future.
      label = subview UILabel, :day_of_week, left: x, text: name
      selectionMarkerLabel = subview UILabel, :day_of_week_overlay, left: x, text: name
      selectionMarkerLabel.userInteractionEnabled = false
      label.when_tapped do
        Logger.checkpoint 'Tap day'
        self.timeSelection = timeSelection.onDate(date)
      end
      declareViewMode :interactive, label
      declareViewMode :interactive, selectionMarkerLabel
      selectionMarkerLabels << selectionMarkerLabel
    end

    # Move the day indicator in front of the background day labels; then move the foreground day labels in front of it.
    # This is simpler than creating them in the right order.
    zOrder = [dayIndicator] + selectionMarkerLabels + [dayIndicatorHandle]
    zOrder.each do |label| label.superview.bringSubviewToFront label end

    observe(dayIndicator, :frame) do
      selectionMarkerLabels.each do |label|
        dx = label.origin.x - dayIndicator.origin.x + DayIndicatorOffset
        label.alpha = 1 - [[dx.abs / 45.0, 1].min, 0].max
        dayIndex = ((dayIndicator.origin.x + DayIndicatorOffset - DayFirstX) / DaySpacing).round
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
        pos = CGPointMake(selectedMarkerLabel.x + DayIndicatorOffset, selectedMarkerLabel.y)
        dayIndicator.origin = pos if dayIndicator.top == 0 # first time
        UIView.animateWithDuration DayIndicatorAnimationSeconds, animations: -> { dayIndicator.x = pos.x }
      end
    end
  end

  def createHourSelectionViews
    hour12Formatter = NSDateFormatter.alloc.init.setDateFormat('h')
    hoursView = subview UIView do
      Hours.each_with_index do |hour, i|
        subview UIView, :hour_blob, left: HourFirstX + i * HourSpacing do
          subview UILabel, :hour_blob_hour, text: (hour % 12).to_s #hour12Formatter.stringFromDate(hour)
          subview UILabel, :hour_blob_am_pm
          subview UILabel, :hour_blob_half_past
        end
      end
    end
    declareViewMode :interactive, hoursView

    @hoursIndicator = subview UIView, :hours_indicator do
      @hourRangeLabel = subview UILabel, :hours_indicator_label
      hourRangeLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth

      subview UIImageView, :hours_left_handle_image
      subview UIImageView, :hours_right_handle_image

    end
    declareViewMode :interactive, hoursIndicator

    # Place the touch targets outside the hours view so that hit testing will recognize that
    # they extend past its margins.
    # Alternatives would be to customize the hours view to render in a subset of its bounds,
    # or to override its hittest method.
    dragHoursHandle = subview UIView, :hours_drag_handle
    leftDragHandle = subview UIView, :hours_left_handle
    rightDragHandle = subview UIView, :hours_right_handle
    dragHoursOptions = {xMinimum: HourFirstX, widthMinimum: (MinHours + 0.5) * HourSpacing, widthFactor: HourSpacing / 2}
    TouchUtils.dragOnTouch hoursIndicator, handle:dragHoursHandle, options:dragHoursOptions
    TouchUtils.dragOnTouch hoursIndicator, handle:leftDragHandle, options:dragHoursOptions.merge(resize:true)
    TouchUtils.resizeOnTouch hoursIndicator, handle:rightDragHandle, options:dragHoursOptions
    [dragHoursHandle, leftDragHandle, rightDragHandle].each do |handle|
      registerTouchEffectHandle handle, target:hoursIndicator
      TouchUtils.bounceOnTap hoursIndicator, handle:handle
    end

    @summaryViewHoursLabel = subview UILabel, :summary_hours
    @summaryViewHoursLabelFg = subview UILabel, :summary_hours
    declareViewMode :summary, summaryViewHoursLabelFg
    declareViewMode :summary, summaryViewHoursLabel

    # TODO use dateFormatter, to honor 24hr time. How to keep it from stripping the period?
    hourMinuteFormatter = NSDateFormatter.alloc.init.setDateFormat('h:mm')
    hourMinutePeriodFormatter = NSDateFormatter.alloc.init.setDateFormat('h:mma')
    periodFormatter = NSDateFormatter.alloc.init.setDateFormat('a')
    observe(self, :timeSelection) do |_, timeSpan|
      delegate.timeSelectionDidChangeTo timeSpan if delegate

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
      tooWide = -> { hoursIndicator.size.width > 0 and labelAS.size.width > hoursIndicator.size.width - hoursIndicator.layer.cornerRadius }
      labelAS = createHourRangeString.(labelString.sub(/:00/, '')) if tooWide.()
      labelAS = createHourRangeString.(labelString.gsub(/:00/, '')) if tooWide.()
      labelAS = createHourRangeString.(labelString.gsub(/:00/, ''), true) if tooWide.()
      labelAS = createHourRangeString.(labelString.gsub(/:00/, '').gsub(/:30/, '½'), true) if tooWide.()

      hourRangeLabel.attributedText = NSAttributedString.alloc.initWithAttributedString(labelAS)
      summaryViewHoursLabelFg.attributedText = NSAttributedString.alloc.initWithAttributedString(labelAS)
      summaryViewHoursLabel.attributedText = NSAttributedString.alloc.initWithAttributedString(labelAS)
    end

    timeSpanHoursUpdater = Debounced.new 0.25 do
      # summaryViewHoursLabel.frame = hoursIndicator.frame
      startHour = FirstHourNumber + ((hoursIndicator.left - HourFirstX) * 2 / HourSpacing).round / 2.0
      endHour = FirstHourNumber + ((hoursIndicator.right - HourFirstX) * 2 / HourSpacing).round / 2.0 - 0.5
      startHour = [startHour, FirstHourNumber].max
      endHour = [endHour, startHour + MinHours].max
      self.timeSelection = timeSelection.betweenTimes(startHour, endHour)
    end

    observe(hoursIndicator, :frame) do timeSpanHoursUpdater.fire! end
  end


  #
  # Handles
  #

  public

  # Do this on touch for immediae feedback. The gesture recognizers don't fire until the gesture has started.
  def touchesBegan(touches, withEvent:event)
    super
    for touch in touches
      target = findTouchEffectHandleTarget(touch)
      TouchUtils.showDraggableState(target, began:true, animated:true) if target
    end
  end

  # This is not called (why?), so the target is instead restored in the gesture handlers
  # def touchesEnded(touches, withEvent:event)

  private

  def registerTouchEffectHandle(handle, target:target)
    @touchHandlesTargets ||= []
    @touchHandlesTargets << [handle, target]
  end

  def findTouchEffectHandleTarget(touch)
    for handle, target in @touchHandlesTargets
      return target if touch.view == handle
    end
    return nil
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
    # FIXME daylight savings
    date.dateByAddingHours(hour.floor).dateByAddingMinutes((hour * 60).floor % 60)
  end
end
