class Sitter
  attr_reader :name
  attr_reader :age
  attr_reader :description
  attr_accessor :active
  class << self
    attr_accessor :added
    attr_accessor :suggested
  end

  def self.all
    @sitters ||= self.initializeFromJSON(self.json)
  end

  def self.initializeFromJSON(json)
    @sitters = json.map { |data| self.new(data) }
  end

  def self.added
    initial_sitter_count = 6
    @added ||= self.all[0...initial_sitter_count]
  end

  def self.added=(sitters)
    self.willChangeValueForKey :added
    @added = sitters
    self.didChangeValueForKey :added

    self.willChangeValueForKey :suggested
    @suggested = nil
    self.didChangeValueForKey :suggested
  end

  def self.suggested
    @suggested ||= @sitters - @added
  end

  def self.setAddedCount(n)
    delta = n - self.added.length
    self.added = self.added[0...n] if delta < 0
    self.added += (self.all - self.added)[0...delta] if 0 < delta
  end

  def self.canAdd(sitter)
    return false if self.added.length >= 7
    return false if self.added.include?(sitter)
    return true
  end

  def self.addSitter(sitter)
    # instead of <<, for KVO
    self.added = self.added + [sitter] if self.canAdd(sitter)
  end

  def initialize(data)
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

  private

  def self.json
    @json ||= begin
      path = NSBundle.mainBundle.pathForResource('sitters', ofType:'json')
      stream = NSInputStream.inputStreamWithFileAtPath(path)
      stream.open
      begin
        NSJSONSerialization.JSONObjectWithStream(stream, options:0, error:nil)
      ensure
        stream.close
      end
    end
  end

  def self.save(data)
    stream = NSOutputStream.outputStreamToFileAtPath(stream, append:false)
    writeJSONObject:data, toStream:stream, options:0, error:nil
  end
end
