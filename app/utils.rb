NSNumberFormatterSpellOutStyle = 5 unless Object.const_defined?(:NSNumberFormatterSpellOutStyle)

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

def addDragger(dragger, options={})
  target = dragger.superview
  xMin = options[:min] || 0
  initialPosition = nil
  animator = nil
  attachmentBehavior = nil
  dragger.userInteractionEnabled = true
  dragger.when_panned do |recognizer|
    pt = recognizer.translationInView(target.superview)

    case recognizer.state
    when UIGestureRecognizerStateBegan
      initialPosition = target.origin

      # animator ||= UIDynamicAnimator.alloc.initWithReferenceView(target.superview)
      # animator.removeAllBehaviors

    when UIGestureRecognizerStateChanged
      # target.tx = pt.x

      x = [initialPosition.x + pt.x, xMin].max
      x = [x, 320 - target.size.width / 2].min
      target.origin = [x, target.origin.y]

    when UIGestureRecognizerStateEnded
      # dragger.isDragging = false

      factor = options[:factor] || 1
      x = ((target.origin.x - xMin) / factor).round * factor + xMin
      x = [x, xMin].max

      # itemBehavior = UIDynamicItemBehavior.alloc.initWithItems([target])
      # itemBehavior.allowsRotation = false
      # itemBehavior.density = target.size.width * target.size.height / 3000
      # animator.addBehavior itemBehavior

      # snapBehavior = UISnapBehavior.alloc.initWithItem(target, snapToPoint:[x + target.center.x - target.origin.x, target.center.y])
      # animator.addBehavior(snapBehavior)

      UIView.animateWithDuration 0.1,
        animations: lambda {
          # target.tx = 0
          target.x = [x, xMin].max
        }
    end
  end

  dragger.when_tapped do
    xStart = target.x
    firstBounceTime = 0.2
    elasticity = 0.5
    animations = []
    3.times do |i|
      ratio = elasticity ** i
      bounceTime = firstBounceTime * ratio
      animations << [bounceTime / 2, 5 * ratio, UIViewAnimationOptionCurveEaseOut]
      animations << [bounceTime / 2, 0, UIViewAnimationOptionCurveEaseIn]
    end
    step = Proc.new do
      dur, dx, options = animations.shift
      UIView.animateWithDuration dur, delay:0, options:options,
        animations: lambda { target.x = xStart + dx },
        completion: lambda { |finished| step.call if animations.any? }
    end
    step.call #unless dragging
  end
end

def addResizer(dragger, options={})
  target = dragger.superview
  minWidth = options[:minWidth] || 0
  initialSize = nil
  fudge = 21
  dragger.userInteractionEnabled = true
  dragger.when_panned do |recognizer|
    pt = recognizer.translationInView(target.superview)
    case recognizer.state
    when UIGestureRecognizerStateBegan
      initialSize = target.size
    when UIGestureRecognizerStateChanged
      target.width = [initialSize.width + pt.x, minWidth].max
      dragger.x = target.width - dragger.width + fudge
    when UIGestureRecognizerStateEnded
      factor = options[:factor] || 1
      width = (target.width / factor).round * factor
      UIView.animateWithDuration 0.1,
        animations: lambda {
          target.width = [width, minWidth].max
          dragger.x = target.width - dragger.width + fudge
        }
    end
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
