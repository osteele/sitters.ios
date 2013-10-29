class ExpirationChecker
  include BW::KVO

  attr_accessor :expired

  def self.instance
    Dispatch.once { @instance ||= new }
    @instance
  end

  def initialize
    @expired = false

    Dispatch::Queue.main.async do
      self.expired = true if expirationDate and expirationDate < NSDate.date
    end

    app = UIApplication.sharedApplication.delegate
    app.firebase['expirationDate'].on(:value) do |snapshot|
      date = ISO8601DateFormatter.dateFromString(snapshot.value)
      self.expired = true if date and buildDate < date
    end
  end

  def buildDate
    app = UIApplication.sharedApplication.delegate
    return app.buildDate
  end

  def expirationDate
    @expirationDate ||= dateFromProperty('ExpirationDate')
  end

  private

  def dateFromProperty(propertyName)
    dateString = NSBundle.mainBundle.objectForInfoDictionaryKey(propertyName)
    return nil unless dateString
    return ISO8601DateFormatter.dateFromString(dateString)
  end
end