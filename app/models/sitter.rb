class Sitter
  attr_reader :id
  attr_reader :name
  attr_accessor :active

  def self.all
    # until sitters come in from network
    @sitters ||= []
  end

  def self.loadRecommendedSitters
    if App.delegate.demo?
      self.loadRecommendedSittersFromFile
    else
      self.loadRecommendedSittersFromNetwork
    end
  end

  private

  def self.loadRecommendedSittersFromFile
    path = NSBundle.mainBundle.URLForResource('sitters', withExtension:'json')
    error = Pointer.new(:id)
    content = NSString.stringWithContentsOfFile(path, encoding:NSUTF8StringEncoding, error:error)
    Logger.error error[0].description if error[0]
    sitterData = NSJSONSerialization.JSONObjectWithData(content.dataUsingEncoding(NSUTF8StringEncoding), options:NSJSONReadingMutableLeaves, error:nil)
    Logger.error error[0].description if error[0]
    Sitter.updateFromArray sitterData
  end

  def self.loadRecommendedSittersFromNetwork
    Storage.instance.onCachedFirebaseValue('sitter', {cacheVersion:2}) do |sitterData|
      Sitter.updateFromArray sitterData
    end
  end

  def self.updateFromArray(sitterData)
    sitterData = sitterData.values if sitterData.instance_of?(Hash)
    self.willChangeValueForKey :all
    @sitters ||= []
    @sitters = sitterData.map do |data|
      sitter = findSitterById(data['id'])
      sitter ? sitter.tap { |s| s.updateFrom(data) } : self.new(data)
    end.reject(&:nil?)
    self.didChangeValueForKey :all
    App.notification_center.postNotification ApplicationDidLoadDataNotification
  end

  public

  def self.findSitterById(sitter_id)
    return @sitters.find { |sitter| sitter.id.to_s == sitter_id.to_s }
  end

  def initialize(data)
    self.updateFrom(data)
  end

  def updateFrom(data)
    @id = data['id']
    @name = data['name']
    @age = data['age']
    @description = data['description']
    @hours = data['hours'] || {}
  end

  def firstName; self.name.split[0]; end
  def lastName; self.name[/\s(\S+)/, 1]; end

  # Work around error e.g.:
  #  method `description' created by attr_reader/writer or define_method cannot be called from Objective-C.
  # Please manually define the method instead (using the `def' keyword)
  def age; @age; end
  def description; @description; end

  def availableAt(timespan)
    @@hoursAvailableDateKey ||= NSDateFormatter.alloc.init.setDateFormat('E')
    day = @@hoursAvailableDateKey.stringFromDate(timespan.date)
    hours = @hours[day] || []
    return hours.any? { |startHour, endHour| startHour <= timespan.startHour and timespan.endHour <= endHour }
  end

  def imagePath
    "sitters/#{firstName.downcase}.jpg"
  end

  def image
    @image ||= UIImage.imageNamed(imagePath)
  end

  def maskedImage
    @maskedImage ||= UIImage.imageWithCGImage(SitterCircleController.sitterImage(self))
  end
end
