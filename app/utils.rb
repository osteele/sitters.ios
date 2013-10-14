NSNumberFormatterSpellOutStyle = 5 unless Object.const_defined?(:NSNumberFormatterSpellOutStyle)
UIFontDescriptorTraitBold = 1 << 1 unless Object.const_defined?(:UIFontDescriptorTraitBold)

class UIView < UIResponder
  def top; self.origin.x; end
  def left; origin.x; end
  def height; self.size.height; end
  def width; self.size.width; end
  def top=(y); self.origin = [self.origin.x, y]; end
  def left=(x); self.origin = [x, self.origin.y]; end
  def height=(height); self.size = [self.size.width, height]; end
  def width=(width); self.size = [width, self.size.height]; end
  alias_method :x, :left
  alias_method :y, :top
  alias_method :x=, :left=
  alias_method :y=, :top=

  def tx; self.transform.tx; end
  def ty; self.transform.ty; end
  def tx=(tx); transform = self.transform; transform.tx = tx; self.transform = transform; end
  def ty=(ty); transform = self.transform; transform.ty = ty; self.transform = transform; end
end

def dateFormatter(template)
  template = NSDateFormatter.dateFormatFromTemplate(template, options:0, locale:NSLocale.currentLocale)
  dayLabelFormatter = NSDateFormatter.alloc.init.setDateFormat(template)
end

class Scheduler
  attr_reader :pending

  def self.after(delay, &block)
    self.new.after(delay, &block)
  end

  def after(delay, &block)
    @block = block
    @timer = NSTimer.scheduledTimerWithTimeInterval(delay, target:self, selector:'fire', userInfo:nil, repeats:false)
    @pending = true
    return self
  end

  def fire
    @pending = false
    @block.call
  end
end

class Debounced
  def initialize(delay, &block)
    @delay = delay
    @block = block
    @scheduler = Scheduler.new
  end

  def fire!
    return if @scheduler.pending
    @scheduler.after @delay, &@block
  end
end

# Don't need the overhead of a UICollectionViewLayout and associated classes,
# since there'too few cells for a flyweight and there's just the one fixed layout.
class HexagonLayout
  attr_accessor :cellWidth, :cellHeight, :leftMargin

  def initialize
    @cellWidth = 96
    @cellHeight = 84
    @leftMargin = 19
  end

  def applyTo(views)
    views.each_with_index do |view, i|
      view.origin = positionAt(i)
    end
  end

  def positionAt(n)
    cellsPerEvenRow = 2
    cellsPerOddRow = cellsPerEvenRow + 1
    cellsPerRowPair = cellsPerEvenRow + cellsPerOddRow
    row, col, rowType = [2 * (n / cellsPerRowPair).floor, n % cellsPerRowPair, :even]
    row, col, rowType = [row + 1, col - cellsPerEvenRow, :odd] if col >= cellsPerEvenRow
    col += 0.5 if rowType == :even
    [leftMargin + col * cellWidth, row * cellHeight]
  end
end
