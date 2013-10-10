class BookingController < UIViewController
  private
  def createTimeSelector
    weekStartDay = NSDate.date.dateAtStartOfDay
    tallSizeOnlyViews = []
    shortSizeOnlyViews = []

    @timeSelectorView = subview TimeSelector, styleId: :time_selector do
      dayLabelFormatter = dateFormatter('EEEE, MMMM d')
      dayLabel = subview UILabel, styleClass: :date

      firstDayX = 3
      dayspacing = 44

      daySelectionMarker = nil
      daySelectionMarkerOffset = 5
      dayLabels = []
      selectionMarkerLabels = []
      weekdayDates = (0...7).map do |day| weekStartDay.dateByAddingDays(day) end
      daySelectionMarker = subview UIButton, styleClass: :selected_day do
        handle = subview UIView, width: 100, height: 100
        addDragger handle, min: firstDayX + 5, factor: dayspacing
      end
      tallSizeOnlyViews << daySelectionMarker

      weekdayDates.each_with_index do |date, i|
        x = firstDayX + i * dayspacing
        name = NSDateFormatter.alloc.init.setDateFormat('EEEEE').stringFromDate(date)
        # Create a separate view for the selection marker label so that we can animate
        # the color transition. Animation animates opacity but not color.
        # A custom view could animate its text color, but the current system leaves
        # the possibility for a wider variety of transition effects in the future.
        label = subview UILabel, text: name, styleClass: :day_of_week, left: x
        selectionMarkerLabel = subview UILabel, text: name, styleClass: 'day_of_week overlay', left: x
        selectionMarkerLabel.userInteractionEnabled = false
        label.when_tapped do
          self.selectedTimeSpan = selectedTimeSpan.onDate(date)
        end
        dayLabels << label
        selectionMarkerLabels << selectionMarkerLabel
      end
      tallSizeOnlyViews += dayLabels
      tallSizeOnlyViews += selectionMarkerLabels

      daySelectionMarker.superview.bringSubviewToFront daySelectionMarker
      selectionMarkerLabels.each do |label| label.superview.bringSubviewToFront label end

      observe(daySelectionMarker, :frame) do
        selectionMarkerLabels.each do |label|
          dx = label.origin.x - daySelectionMarker.origin.x + daySelectionMarkerOffset
          label.alpha = 1 - [[dx.abs / 45.0, 1].min, 0].max
          dayIndex = ((daySelectionMarker.origin.x + daySelectionMarkerOffset - firstDayX) / dayspacing).round
          dayIndex = [[dayIndex, 0].max, weekdayDates.length - 1].min
          date = weekdayDates[dayIndex]
          self.selectedTimeSpan = selectedTimeSpan.onDate(date) unless selectedTimeSpan.date == date
        end
      end

      observe(self, :selectedTimeSpan) do |previousTimeSpan, timeSpan|
        unless previousTimeSpan and previousTimeSpan.date == timeSpan.date
          dayLabel.text = dayLabelFormatter.stringFromDate(timeSpan.date)
          currentWeekDayIndex = weekdayDates.index(timeSpan.date)
          selectedMarkerLabel = selectionMarkerLabels[currentWeekDayIndex]
          UIView.animateWithDuration 0.3,
            animations: lambda {
              daySelectionMarker.origin = [selectedMarkerLabel.origin[0] + daySelectionMarkerOffset, selectedMarkerLabel.origin[1]]
            }
          end
      end

      firstHourOffset = 10
      firstHourNumber = 18
      hourWidth = 58
      hoursView = subview UIView do
        [6, 7, 8, 9, 10, 11].each_with_index do |hour, i|
          subview UIView, styleClass: :hour_blob, left: 10 + i * 58 do
            # TODO use dateFormatter
            subview UILabel, text: hour.to_s, styleClass: :hour
            subview UILabel, text: 'PM', styleClass: :am_pm
            subview UILabel, text: ':30', styleClass: :half_past
          end
        end
      end
      tallSizeOnlyViews << hoursView

      minHours = 1.5
      hourRangeLabel = nil
      leftDragHandle = rightDragHandle = nil
      hourRangeButton = subview UIButton, styleClass: :hour_range, styleId: :hour_range do
        hourRangeLabel = subview UILabel, styleClass: :hour_range
        hourRangeLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth

        leftDragHandle = subview UIView, :left_dragger, styleClass: :left_dragger, styleId: :left_dragger do
          subview UIView, styleClass: :graphic
        end
        rightDragHandle = subview UIView, :right_dragger, styleClass: :right_dragger, styleId: :right_dragger do
          subview UIView, styleClass: :graphic
        end

        addDragger leftDragHandle, min: firstHourOffset, factor: hourWidth / 2
        addResizer rightDragHandle, minWidth: minHours * hourWidth, factor: hourWidth / 2
      end
      tallSizeOnlyViews << hourRangeButton

      # TODO use dateFormatter, to honor 24hr time. How to keep it from stripping the period?
      hourMinuteFormatter = NSDateFormatter.alloc.init.setDateFormat('h:mm')
      hourMinutePeriodFormatter = NSDateFormatter.alloc.init.setDateFormat('h:mma')
      periodFormatter = NSDateFormatter.alloc.init.setDateFormat('a')
      observe(self, :selectedTimeSpan) do |_, timeSpan|
        startPeriod = periodFormatter.stringFromDate(timeSpan.startTime)
        endPeriod = periodFormatter.stringFromDate(timeSpan.endTime)
        startFormatter = if startPeriod == endPeriod then hourMinuteFormatter else hourMinutePeriodFormatter end
        label = startFormatter.stringFromDate(timeSpan.startTime) + '-' + hourMinuteFormatter.stringFromDate(timeSpan.endTime) + ' ' + endPeriod
        fontName = "HelveticaNeue"
        string = NSMutableAttributedString.alloc.initWithString(label)
        string.addAttribute NSFontAttributeName, value:UIFont.fontWithName(fontName + "-Bold", size:15), range:NSMakeRange(0, label.length)
        string.addAttribute NSFontAttributeName, value:UIFont.fontWithName(fontName, size:8), range:NSMakeRange(label.length - 3, 1)
        string.addAttribute NSFontAttributeName, value:UIFont.fontWithName(fontName, size:10), range:NSMakeRange(label.length - 2, 2)
        hourRangeLabel.attributedText = string
      end

      timeSpanHoursUpdater = Debounced.new 0.5 do
        frame = hourRangeButton.frame
        startHour = firstHourNumber + ((hourRangeButton.origin.x - firstHourOffset) / hourWidth * 2).round / 2.0
        endHour = firstHourNumber + ((hourRangeButton.origin.x + hourRangeButton.size.width - firstHourOffset) / hourWidth * 2).round / 2.0 - 0.5
        startHour = [startHour, firstHourNumber].max
        endHour = [endHour, startHour + minHours].max
        self.selectedTimeSpan = selectedTimeSpan.betweenTimes(startHour, endHour)
      end

      observe(hourRangeButton, :frame) do timeSpanHoursUpdater.fire! end

      @shrinkTimeSelector = Proc.new do
        @timeSelectorSaved = {
          frame: @timeSelectorView.frame,
          hourRangeColor: hourRangeButton.backgroundColor,
          hourRangeFrame: hourRangeButton.frame,
        }
        @timeSelectorView.origin = [0, 64]
        @timeSelectorView.size = [@timeSelectorView.size.width, 55]
        tallSizeOnlyViews.each do |view| view.alpha = 0 end
        shortSizeOnlyViews.each do |view| view.alpha = 1 end
      end

      @unshrinkTimeSelector = Proc.new do
        return unless @timeSelectorSaved
        @timeSelectorView.frame = @timeSelectorSaved[:frame]
        hourRangeButton.frame = @timeSelectorSaved[:hourRangeFrame]
        tallSizeOnlyViews.each do |view| view.alpha = 1 end
        shortSizeOnlyViews.each do |view| view.alpha = 0 end
      end
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
