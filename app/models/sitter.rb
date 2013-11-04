class Sitter
  attr_reader :id
  attr_reader :name
  attr_reader :age
  attr_reader :description
  attr_accessor :active

  def self.all
    # until sitters come in from network
    @sitters ||= []
  end

  def self.updateFrom(json)
    self.willChangeValueForKey :all
    @sitters ||= []
    @sitters = json.map do |data|
      sitter = findSitterById(data['id'])
      sitter ? sitter.tap { |s| s.updateFrom(data) } : self.new(data)
    end.reject(&:nil?)
    self.didChangeValueForKey :all
  end

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
  def description; @description; end
  def age; @age; end

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
