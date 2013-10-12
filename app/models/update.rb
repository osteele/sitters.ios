class Update
  attr_accessor :contact
  attr_accessor :description
  attr_accessor :timestamp

  def self.all
    [
      new('Steve and Diane Smith', 'added a sitter', '4:12 PM'),
      new('Maggie McConnell', 'added a parent', '3:31 PM'),
      new('Jane and Ted Phillips', 'introduced you to Cindy King', '2:48 PM'),
      new('Layla Smith', 'added a parent', 'yesterday'),
      new('Gina Marelli', 'would like to be interviewed', 'yesterday'),
      new('Alex and Jen Handy', 'added a sitter', '2d ago'),
      new('Michelle Shaffer', 'would like to be interviewed', '3d ago'),
      new('Tim and Elisa Rendo', 'added a sitter', '3d ago'),
      new('Maggie McConnell', 'added a parent', '5d ago'),
    ]
  end

  def self.unread
    @unread ||= self.all[0...3]
  end

  def self.clear
    @unread = []
  end

  def initialize(contact, description, timestamp)
    self.contact = contact
    self.description = description
    self.timestamp = timestamp
  end

  def image
    person ? person.image : UIImage.imageNamed("people/#{self.contact.downcase.gsub(/ /, '-')}.jpg")
  end

  def person
    Sitter.all.find { |sitter| sitter.name == self.contact }
  end

  def today?
    self.timestamp =~ /[AP]M$/
  end
end
