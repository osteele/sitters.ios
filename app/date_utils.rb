class NSDate
  def ISO8601StringFromDate
    ISO8601DateFormatterInstance.stringFromDate(self)
  end

  def self.dateFromISO8601String(string)
    @formatter ||= ISO8601DateFormatter.alloc.init
    @formatter.dateFromString(string)
  end

  def relativeDayFromDate
    case
      when self.isToday then "today"
      when self.isTomorrow then "tomorrow"
      else "on #{dateFormatter('EEEE').stringFromDate(self)}"
    end
  end
end

# Returns an NSDateFormatter for `template` for the current locale.
# This is not cached. It's the caller's responsibility to update this if the locale changes.
def dateFormatter(template)
  template = NSDateFormatter.dateFormatFromTemplate(template, options:0, locale:NSLocale.currentLocale)
  dayLabelFormatter = NSDateFormatter.alloc.init.setDateFormat(template)
end
