class Update
  attr_accessor :contact
  attr_accessor :description
  attr_accessor :timestamp

  def self.all
    [
      new("Steve and Diane Smith", "added a sitter", "4:12 PM"),
      new("Maggie McConnell", "added a parent", "3:31 PM"),
      new("Jane and Ted Phillips", "introduced you to Cindy King", "yesterday"),
      new("Layla Smith", "added a parent", "yesterday"),
      new("Gina Tarelli", "would like to be interviewed", "yesterday ago"),
      new("Alex and Jen Handy", "added a sitter", "2d ago"),
      new("Michelle Shaffer", "would like to be interviewed", "3d ago"),
      new("Tim and Elisa Rendo", "added a sitter", "3d ago"),
      new("Maggie McConnell", "added a parent", "5d ago"),
    ]
  end

  def initialize(contact, description, timestamp)
    self.contact = contact
    self.description = description
    self.timestamp = timestamp
  end
end
