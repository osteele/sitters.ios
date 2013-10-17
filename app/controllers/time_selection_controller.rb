class TimeSelectionController < UIViewController
  include BW::KVO

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
    self.timeSelection = TimeSelection.new(today, 18, 21)
  end

  private

  attr_accessor :tallSizeOnlyViews
  attr_accessor :shortSizeOnlyViews

  layout do
    self.view.stylename = :time_selector

    @tallSizeOnlyViews = []
    @shortSizeOnlyViews = []

    createDaySelectorViews
    createHourSelectorViews
  end

  def createDaySelectorViews
    firstDayOfDisplayedWeek = NSDate.date.dateAtStartOfDay
    dayLabelFormatter = dateFormatter('EEEE, MMMM d')
    dayLabel = subview UILabel, :date

    firstDayX = 3
    dayspacing = 44

    daySelectionMarker = nil
    daySelectionMarkerOffset = 5
    dayLabels = []
    selectionMarkerLabels = []
    weekdayDates = (0...7).map do |day| firstDayOfDisplayedWeek.dateByAddingDays(day) end
    daySelectionMarker = subview UIView, :day_selection_marker do
      handle = subview UIView, width: 100, height: 100
      options = {
        xMinimum: firstDayX + daySelectionMarkerOffset,
        xMaximum: firstDayX + daySelectionMarkerOffset + 6 * dayspacing,
        widthFactor: dayspacing
      }
      TouchUtils.dragOnTouch handle.superview, handle:handle, options:options
      TouchUtils.bounceOnTap handle.superview, handle:handle
    end
    daySelectionMarker.layer.cornerRadius = 17
    daySelectionMarker.layer.shadowRadius = 1.5
    daySelectionMarker.layer.shadowOffset = [0, 2]
    daySelectionMarker.layer.shadowOpacity = 0.5
    tallSizeOnlyViews << daySelectionMarker

    weekdayDates.each_with_index do |date, i|
      x = firstDayX + i * dayspacing
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
      dayLabels << label
      selectionMarkerLabels << selectionMarkerLabel
    end
    self.tallSizeOnlyViews += dayLabels
    self.tallSizeOnlyViews += selectionMarkerLabels

    daySelectionMarker.superview.bringSubviewToFront daySelectionMarker
    selectionMarkerLabels.each do |label| label.superview.bringSubviewToFront label end

    observe(daySelectionMarker, :frame) do
      selectionMarkerLabels.each do |label|
        dx = label.origin.x - daySelectionMarker.origin.x + daySelectionMarkerOffset
        label.alpha = 1 - [[dx.abs / 45.0, 1].min, 0].max
        dayIndex = ((daySelectionMarker.origin.x + daySelectionMarkerOffset - firstDayX) / dayspacing).round
        dayIndex = [[dayIndex, 0].max, weekdayDates.length - 1].min
        date = weekdayDates[dayIndex]
        self.timeSelection = timeSelection.onDate(date) unless timeSelection.date == date
      end
    end

    observe(self, :timeSelection) do |previousTimeSelection, timeSpan|
      unless previousTimeSelection and previousTimeSelection.date == timeSpan.date
      # return if previousTimeSelection and previousTimeSelection.date == timeSpan.date
        dayLabel.text = dayLabelFormatter.stringFromDate(timeSpan.date)
        currentWeekDayIndex = weekdayDates.index(timeSpan.date)
        selectedMarkerLabel = selectionMarkerLabels[currentWeekDayIndex]
        pos = [selectedMarkerLabel.x + daySelectionMarkerOffset, selectedMarkerLabel.y]
        daySelectionMarker.origin = pos if daySelectionMarker.top == 0 # first time
        UIView.animateWithDuration 0.3,
          animations: lambda {
            daySelectionMarker.x = pos[0]
          }
      end
    end
  end

  def createHourSelectorViews
    firstHourOffset = 10
    firstHourNumber = 18
    hourWidth = 58
    hoursView = subview UIView do
      [6, 7, 8, 9, 10, 11].each_with_index do |hour, i|
        subview UIView, :hour_blob, left: 10 + i * 58 do
          # TODO use dateFormatter
          subview UILabel, :hour_blob_hour, text: hour.to_s
          subview UILabel, :hour_blob_am_pm, text: 'PM'
          subview UILabel, :hour_blob_half_past, text: ':30'
        end
      end
    end
    tallSizeOnlyViews << hoursView

    minHours = 1.5
    hourRangeLabel = nil
    hourSlider = subview UIView, :hour_slider do
      hourRangeLabel = subview UILabel, :hour_slider_label
      hourRangeLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth

      leftDragHandle = subview UIView, :hour_left_handle do
        subview UIImageView, :hour_left_handle_image
      end
      rightDragHandle = subview UIView, :hour_right_handle do
        subview UIImageView, :hour_right_handle_image
      end

      target = leftDragHandle.superview
      resizeOptions = {xMinimum: firstHourOffset, widthMinimum: (minHours + 0.5) * hourWidth, widthFactor: hourWidth / 2}
      TouchUtils.dragOnTouch target, handle:leftDragHandle, options:resizeOptions
      TouchUtils.resizeOnTouch target, handle:rightDragHandle, options:resizeOptions
      TouchUtils.bounceOnTap target, handle:leftDragHandle
      TouchUtils.bounceOnTap target, handle:rightDragHandle
      # FIXME replace this by a constraint
      observe(target, :frame) do rightDragHandle.x = target.width - 20 end
    end
    hourSlider.layer.cornerRadius = 17
    hourSlider.layer.shadowRadius = 3
    hourSlider.layer.shadowOffset = [0, 1]
    hourSlider.layer.shadowOpacity = 0.5
    # hourSlider.layer.masksToBounds = false
    # hourSlider.layer.shadowPath = UIBezierPath.bezierPathWithRoundedRect(hourSlider.bounds, cornerRadius:17).CGPath

    tallSizeOnlyViews << hourSlider

    staticHoursLabel = subview UILabel, textAlignment: NSTextAlignmentCenter, textColor: UIColor.whiteColor, origin: [0, 18], size: [320, 30], alpha: 0
    shortSizeOnlyViews << staticHoursLabel

    # TODO use dateFormatter, to honor 24hr time. How to keep it from stripping the period?
    hourMinuteFormatter = NSDateFormatter.alloc.init.setDateFormat('h:mm')
    hourMinutePeriodFormatter = NSDateFormatter.alloc.init.setDateFormat('h:mma')
    periodFormatter = NSDateFormatter.alloc.init.setDateFormat('a')
    observe(self, :timeSelection) do |_, timeSpan|
      delegate.timeSelectionChanged timeSpan if delegate
      startPeriod = periodFormatter.stringFromDate(timeSpan.startTime)
      endPeriod = periodFormatter.stringFromDate(timeSpan.endTime)
      startFormatter = if startPeriod == endPeriod then hourMinuteFormatter else hourMinutePeriodFormatter end
      label = startFormatter.stringFromDate(timeSpan.startTime) + '-' + hourMinuteFormatter.stringFromDate(timeSpan.endTime) + ' ' + endPeriod
      labelFont = hourRangeLabel.font
      boldFontName = UIFont.fontWithName(labelFont.familyName, size:15).fontDescriptor.fontDescriptorWithSymbolicTraits(UIFontDescriptorTraitBold).postscriptName
      boldFont = UIFont.fontWithName(boldFontName, size:15)
      normalFont = UIFont.fontWithName(labelFont.familyName, size: labelFont.pointSize)
      string = NSMutableAttributedString.alloc.initWithString(label)
      string.addAttribute NSFontAttributeName, value:boldFont, range:NSMakeRange(0, label.length)
      string.addAttribute NSFontAttributeName, value:normalFont.fontWithSize(8), range:NSMakeRange(label.length - 3, 1)
      string.addAttribute NSFontAttributeName, value:normalFont.fontWithSize(10), range:NSMakeRange(label.length - 2, 2)
      hourRangeLabel.attributedText = NSAttributedString.alloc.initWithAttributedString(string)
      staticHoursLabel.attributedText = NSAttributedString.alloc.initWithAttributedString(string)
    end

    timeSpanHoursUpdater = Debounced.new 0.5 do
      frame = hourSlider.frame
      startHour = firstHourNumber + ((hourSlider.x + hourSlider.tx - firstHourOffset) / hourWidth * 2).round / 2.0
      endHour = firstHourNumber + ((hourSlider.x + hourSlider.tx + hourSlider.width - firstHourOffset) / hourWidth * 2).round / 2.0 - 0.5
      startHour = [startHour, firstHourNumber].max
      endHour = [endHour, startHour + minHours].max
      self.timeSelection = timeSelection.betweenTimes(startHour, endHour)
    end

    observe(hourSlider, :frame) do timeSpanHoursUpdater.fire! end
  end

  public

  def setHeight(key)
    return if @timeSelectorHeightKey == key
    @timeSelectorHeightKey = key
    view = self.view
    case key
    when :short
      @savedTimeSelectorValues = {
        frame: view.frame,
        alpha: tallSizeOnlyViews.map { |v| [v, v.alpha] }
      }
      view.top = 64
      view.height = 55
      view.setNeedsDisplay
      tallSizeOnlyViews.each do |v| v.alpha = 0 end
      shortSizeOnlyViews.each do |v| v.alpha = 1 end
    when :tall
      savedValues = @savedTimeSelectorValues
      return unless savedValues
      view.frame = savedValues[:frame]
      savedValues[:alpha].each do |v, alpha| v.alpha = alpha end
      shortSizeOnlyViews.each do |v| v.alpha = 0 end
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
