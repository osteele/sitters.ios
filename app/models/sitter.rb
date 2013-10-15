class Sitter
  attr_reader :name
  attr_reader :age
  attr_reader :description
  attr_accessor :active

  def self.all
    @sitters ||= json.map { |data| self.new(data) }
  end

  def self.added
    @added ||= self.all[0...6]
  end

  def self.suggested
    return self.all - self.added
  end

  def initialize(data)
    @name = data['name']
    @age = data['age']
    @description = data['description']
    @hours = data['hours'] || {}
  end

  def firstName; self.name.split[0]; end
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
    @maskedImage ||= UIImage.imageWithCGImage(SitterCircleView.sitterImage(self))
  end

  private

  def self.json
    @json ||= begin
      path = NSBundle.mainBundle.pathForResource('sitters', ofType:'json')
      content = NSString.stringWithContentsOfFile(path ,encoding:NSUTF8StringEncoding, error:nil)
      NSJSONSerialization.JSONObjectWithData(content.dataUsingEncoding(NSUTF8StringEncoding), options:NSJSONReadingMutableLeaves, error:nil)
    end
  end
end
