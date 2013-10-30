class UIFont
  def fontWithSymbolicTraits(traits)
    fontName = fontDescriptor.fontDescriptorWithSymbolicTraits(traits).postscriptName
    return UIFont.fontWithName(fontName, size:pointSize)
  end
end

class UIView < UIResponder
  def top; origin.y; end
  def left; origin.x; end
  def right; origin.x + size.width; end
  def bottom; origin.y + size.height; end
  def height; size.height; end
  def width; size.width; end
  def top=(y); self.origin = [origin.x, y]; end
  def left=(x); self.origin = [x, origin.y]; end
  def height=(height); self.size = [size.width, height]; end
  def width=(width); self.size = [width, size.height]; end
  alias_method :x, :left
  alias_method :y, :top
  alias_method :x=, :left=
  alias_method :y=, :top=

  def tx; self.transform.tx; end
  def ty; self.transform.ty; end
  def tx=(tx); transform = self.transform; transform.tx = tx; self.transform = transform; end
  def ty=(ty); transform = self.transform; transform.ty = ty; self.transform = transform; end
end

# Returns an NSDateFormatter for `template` for the current locale.
# This is not cached. It's the caller's responsibility to update this if the locale changes.
def dateFormatter(template)
  template = NSDateFormatter.dateFormatFromTemplate(template, options:0, locale:NSLocale.currentLocale)
  dayLabelFormatter = NSDateFormatter.alloc.init.setDateFormat(template)
end

# `Scheduler.after seconds, &block` calls `block` after `seconds` seconds.
class Scheduler
  attr_reader :pending

  def self.after(seconds, &block)
    self.new.after(seconds, &block)
  end

  def after(seconds, &block)
    @block = block
    @timer = NSTimer.scheduledTimerWithTimeInterval(seconds, target:self, selector:'fire', userInfo:nil, repeats:false)
    @pending = true
    return self
  end

  def fire
    @pending = false
    @block.call
  end
end

# `fire!` calls `block`, except that it delays or coalesces calls to ensure that it is not called
# more than once per `seconds` seconds.
class Debounced
  def initialize(seconds, &block)
    @delay = seconds
    @block = block
    @scheduler = Scheduler.new
    @nextTime = nil
  end

  def fire!
    return if @scheduler.pending
    now = NSDate.date.timeIntervalSince1970
    if @nextTime and now < @nextTime
      @scheduler.after @delay, do fireAndDelay end
    else
      fireAndDelay
    end
  end

  private

  def fireAndDelay
    @block.call
    @nextTime = NSDate.date.timeIntervalSince1970 + @delay
  end
end

# This implements a subset of the functionality of a UICollectionViewLayout and associated classes.
# It's much simpler than the full protocol since there's too few cells to require a flyweight,
# and there's just the one fixed layout.
class HexagonLayout
  attr_accessor :cellWidth, :cellHeight, :leftMargin

  def initialize
    @cellWidth = 96
    @cellHeight = 84
    @leftMargin = 19
  end

  def applyTo(views)
    views.each_with_index do |view, i|
      view.origin = originForIndex(i)
    end
  end

  def originForIndex(n)
    cellsPerEvenRow = 2
    cellsPerOddRow = cellsPerEvenRow + 1
    cellsPerRowPair = cellsPerEvenRow + cellsPerOddRow
    row, col, rowType = [2 * (n / cellsPerRowPair).floor, n % cellsPerRowPair, :even]
    row, col, rowType = [row + 1, col - cellsPerEvenRow, :odd] if col >= cellsPerEvenRow
    col += 0.5 if rowType == :even
    [leftMargin + col * cellWidth, row * cellHeight]
  end
end

class DataCache
  def self.instance
    Dispatch.once { @instance ||= new }
    @instance
  end

  def database
    @db ||= begin
      cachesDirectoryURL = NSFileManager.defaultManager.URLsForDirectory(NSCachesDirectory, inDomains:NSUserDomainMask).first
      cacheDbURL = cachesDirectoryURL.URLByAppendingPathComponent('cache.db')
      puts "Data cache = #{cacheDbURL.path}"
      db = FMDatabase.databaseWithPath(cacheDbURL.path)
      db.open
      db.executeUpdate <<-SQL
        CREATE TABLE json_cache (
            key VARCHAR(50) PRIMARY KEY
          , version INT
          , json TEXT
          , updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
          , UNIQUE(key));
      SQL
      db
    end
  end

  def withJSONCache(cacheKey, version:cacheVersion, &block)
    data = fetchDataForKey(key, version:cacheVersion)
    if not data and block
      data = block.call
      storeData data, key:cacheKey, version:cacheVersion
    end
    return data
  end

  def fetchDataForKey(cacheKey, version:cacheVersion)
    db = self.database
    results = db.executeQuery(<<-SQL, withArgumentsInArray:[cacheKey, cacheVersion])
      SELECT json FROM json_cache WHERE key=? AND version=?;
    SQL
    if results.next
      json = results.dataNoCopyForColumn(:json)
      error = Pointer.new(:id)
      data = NSJSONSerialization.JSONObjectWithData(json, options:0, error:error)
      NSLog error[0].description if error[0]
      data = nil if error[0]
    end
    return data
  end

  def storeData(data, key:cacheKey, version:cacheVersion)
    db = self.database
    json = BW::JSON.generate(data)
    values = { key: cacheKey, version: cacheVersion, json: json }
    db.executeUpdate <<-SQL, withParameterDictionary:values
      INSERT OR REPLACE INTO json_cache (key, version, json, updated_at) VALUES (:key, :version, :json, CURRENT_TIMESTAMP);
    SQL
  end

  def onCachedFirebaseValue(firebase, path, options={}, &block)
    cacheKey = options[:cacheKey] || path
    cacheVersion = options[:cacheVersion] || 1
    data = fetchDataForKey(cacheKey, version:cacheVersion)
    previous_json = nil
    if data
      previous_json = BW::JSON.generate(data)
      NSLog "Cache hit: #{path}"
      Dispatch::Queue.main.async do
        block.call data
      end
    else
      NSLog "Cache miss: #{path}"
    end
    firebase[path].on(:value) do |snapshot|
      data = snapshot.value
      if not previous_json or previous_json != BW::JSON.generate(data)
        NSLog "Cache update: #{path}"
        storeData data, key:cacheKey, version:cacheVersion
        block.call data
      end
      previous_json = nil
    end
  end
end
