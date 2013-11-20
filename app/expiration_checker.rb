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

    app = App.delegate
    app.firebaseEnvironment['expirationDate'].on(:value) do |snapshot|
      date = NSDate.dateFromISO8601String(snapshot.value)
      self.expired = true if date and buildDate < date
    end
  end

  def buildDate
    app = App.delegate
    return app.buildDate
  end

  def expirationDate
    @expirationDate ||= dateFromProperty('ExpirationDate')
  end

  private

  def dateFromProperty(propertyName)
    dateString = NSBundle.mainBundle.objectForInfoDictionaryKey(propertyName)
    return nil unless dateString
    return NSDate.dateFromISO8601String(dateString)
  end
end
