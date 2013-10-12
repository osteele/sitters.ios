class Sitter
  attr_reader :name
  attr_reader :age
  attr_reader :description
  attr_accessor :active

  def self.all
    @sitters ||= [
      new("Ashley"),
      new("Kayla"),
      new("Kristen Morey"),
      new("Amy Gino"),
      new("Michelle Shaffer"),
      new("Maggie McConnell"),
      new("Gina Marelli"),
      new("Gwen Stephenson"),
      new("Layla Smith"),
    ]
  end

  def self.added
    @added ||= self.all[0...6]
  end

  def self.suggested
    return self.all - self.added
  end

  def initialize(name)
    data = Sitter.json[name]
    @name = name
    @age = data['age']
    @description = data['description']
    @hours = data['hours'] || {}
  end

  def first_name
    self.name.split[0]
  end

  def description; @description; end
  def age; @age; end

  def availableAt(timespan)
    @@hoursAvailableDateKey ||= NSDateFormatter.alloc.init.setDateFormat('E')
    day = @@hoursAvailableDateKey.stringFromDate(timespan.date)
    hours = @hours[day] || []
    return hours.any? { |startHour, endHour| startHour <= timespan.startHour and timespan.endHour <= endHour }
  end

  def image
    @image ||= UIImage.imageNamed("sitters/#{first_name.downcase}.jpg")
  end

  def maskedImage
    @maskedImage ||= UIImage.imageWithCGImage(SitterCircleView.sitterImage(self))
  end

  def self.json
    @json ||= begin
      path = NSBundle.mainBundle.pathForResource('sitters', ofType:'json')
      content = NSString.stringWithContentsOfFile(path ,encoding:NSUTF8StringEncoding, error:nil)
      NSJSONSerialization.JSONObjectWithData(content.dataUsingEncoding(NSUTF8StringEncoding), options:NSJSONReadingMutableLeaves, error:nil)
    end
  end
end
