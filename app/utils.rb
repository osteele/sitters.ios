class UIView < UIResponder
  def top; origin.y; end
  def left; origin.x; end
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
      puts cacheDbURL.path
      db = FMDatabase.databaseWithPath(cacheDbURL.path)
      db.open
      db.executeUpdate <<-SQL
        CREATE TABLE json (
            key VARCHAR(50) PRIMARY KEY
          , version INT
          , json TEXT
          , updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
          , UNIQUE(key));
      SQL
      db
    end
  end

  def withJSONCache(key, version:version, &block)
    db = self.database
    puts "query"
    results = db.executeQuery('SELECT json FROM json WHERE key=? AND version=?;', withArgumentsInArray:[key, version])
    if results.next
      puts "cache hit"
      json = results.dataNoCopyForColumn(:json)
      data = NSJSONSerialization.JSONObjectWithData(json, options:0, error:nil)
    else
      puts "cache miss"
      data = block.call
      json = BW::JSON.generate(data)
      values = { key: key, version: version, json: json }
      db.executeUpdate 'INSERT OR REPLACE INTO json (key, version, json, updated_at) VALUES (:key, :version, :json, CURRENT_TIMESTAMP);',
        withParameterDictionary:values
    end
    return data
  end
end
