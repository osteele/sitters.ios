class SittersController < UIViewController
  private
  def createTimeSelector
    weekStartDay = NSDate.date.dateAtStartOfDay

    @timeSelectorView = subview TimeSelector, styleId: :time_selector do
      dayLabelFormatter = dateFormatter('EEEE, MMMM d')
      dayLabel = subview UILabel, styleClass: :date

      firstDayX = 3
      dayspacing = 44

      daySelectionMarker = subview UIButton, styleClass: :selected_day do
        handle = subview UIView, width: 100, height: 100
        addDragger handle, min: firstDayX + 5, factor: dayspacing
      end

      dayLabels = []
      selectionMarkerLabels = []
      weekdayDates = (0...7).map do |day| weekStartDay.dateByAddingDays(day) end
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

      daySelectionMarkerOffset = 5
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
        # return if previousTimeSpan and previousTimeSpan.date == timeSpan.date
        dayLabel.text = dayLabelFormatter.stringFromDate(timeSpan.date)
        currentWeekDayIndex = weekdayDates.index(timeSpan.date)
        selectedMarkerLabel = selectionMarkerLabels[currentWeekDayIndex]
        UIView.animateWithDuration 0.3,
          animations: lambda {
            daySelectionMarker.origin = [selectedMarkerLabel.origin[0] + daySelectionMarkerOffset, selectedMarkerLabel.origin[1]]
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

      minHours = 1.5
      range_label = nil
      range_button = subview UIButton, styleClass: :hour_range, styleId: :hour_range do
        range_label = subview UILabel, styleClass: :hour_range
        range_label.autoresizingMask = UIViewAutoresizingFlexibleWidth

        leftDragHandle = subview UIView, :left_dragger, styleClass: :left_dragger, styleId: :left_dragger do
          subview UIView, styleClass: :graphic
        end
        rightDragHandle = subview UIView, :right_dragger, styleClass: :right_dragger, styleId: :right_dragger do
          subview UIView, styleClass: :graphic
        end

        addDragger leftDragHandle, min: firstHourOffset, factor: hourWidth / 2
        addResizer rightDragHandle, minWidth: minHours * hourWidth, factor: hourWidth / 2
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
        fontName = "HelveticaNeue"
        string = NSMutableAttributedString.alloc.initWithString(label)
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
