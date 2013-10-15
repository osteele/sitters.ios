class Update
  attr_reader :contact
  attr_reader :description
  attr_reader :timestamp

  def self.all
    @updates ||= self.json.map { |data| self.new(data) }
  end

  def self.unread
    @unread ||= self.all[0...3]
  end

  def self.clear
    @unread = []
  end

  def initialize(data)
    @contact = data['contact']
    @description = data['description']
    @timestamp = data['timestamp']
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

  private

  def self.json
    @json ||= begin
      path = NSBundle.mainBundle.pathForResource('updates', ofType:'json')
      content = NSString.stringWithContentsOfFile(path ,encoding:NSUTF8StringEncoding, error:nil)
      NSJSONSerialization.JSONObjectWithData(content.dataUsingEncoding(NSUTF8StringEncoding), options:NSJSONReadingMutableLeaves, error:nil)
    end
  end
end
