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
      new("Michelle Schaffer"),
      new("Maggie McConnell"),
      new("Gina Marelli"),
      new("Gwen Stephenson"),
      new("Layla Smith"),
    ]
  end

  def self.suggested
    return self.all.reject { |s| s.active }
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

  def availableAt(timespan)
    @@formatter ||= NSDateFormatter.alloc.init.setDateFormat('E')
    day = @@formatter.stringFromDate(timespan.date)
    return false unless hours = @hours[day]
    return hours.any? { |startHour, endHour| startHour <= timespan.startHour and timespan.endHour <= endHour }
  end

  def image
    @image ||= UIImage.imageNamed("sitters/#{first_name.downcase}.png")
  end

  def self.json
    @json ||= begin
      path = NSBundle.mainBundle.pathForResource('sitters', ofType:'json')
      content = NSString.stringWithContentsOfFile(path ,encoding:NSUTF8StringEncoding, error:nil)
      NSJSONSerialization.JSONObjectWithData(content.dataUsingEncoding(NSUTF8StringEncoding), options:NSJSONReadingMutableLeaves, error:nil)
    end
  end
end
