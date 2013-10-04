class Sitter
  attr_accessor :name
  attr_accessor :age
  attr_accessor :description

  def self.all
    [
      new("Ashley", 18),
      new("Kayla", 16),
      new("Kristen Morey", 14, "Susie Morey’s sister"),
      new("Amy Gino", 12, "Ken and Stacy Reno’s sitter"),
      new("Michelle Schaffer", 16, "Pete and Lisa Schaffer’s daughter"),
      new("Maggie McConnell", 28, "Leslie McConnell’s mother"),
      new("Gina Marelli", 15, "Kayla Brenner’s best friend"),
      new("Gwen Stephenson", 24, "Isabella Moreno’s teacher"),
      new("Layla Smith", 16, "Steve and Diane Smith’s sitter"),
    ]
  end

  def initialize(name, age, description="")
    self.name = name
    self.age = age
    self.description = description
  end

  def first_name
    self.name.split[0]
  end

  def image
    @image ||= UIImage.imageNamed("sitters/#{first_name.downcase}.png")
  end
end
