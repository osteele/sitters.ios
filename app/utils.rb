NSNumberFormatterSpellOutStyle = 5 unless Object.const_defined?(:NSNumberFormatterSpellOutStyle)

class UIView < UIResponder
  def top; origin.x; end
  def left; origin.x; end
  def height; size.height; end
  def width; size.width; end
  def top=(y); self.origin = [origin.x, y]; end
  def left=(x); self.origin = [x, origin.y]; end
  def height=(height); self.size = [size.width, height]; end
  def width=(width); self.size = [width, size.width]; end
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
  # dragger.instance_eval do
  #   attr_accessor :isDragging
  # end

  target = dragger.superview
  xMin = options[:min] || 0
  initialPosition = nil
  animator = nil
  # dragger.isDragging = false
  attachmentBehavior = nil
  dragger.userInteractionEnabled = true
  dragger.when_panned do |recognizer|
    pt = recognizer.translationInView(target.superview)

    case recognizer.state
    when UIGestureRecognizerStateBegan
      initialPosition = target.origin
      # dragger.isDragging = true

      # animator ||= UIDynamicAnimator.alloc.initWithReferenceView(target.superview)
      # animator.removeAllBehaviors

    when UIGestureRecognizerStateChanged
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
          target.origin = [[x, options[:min] || 0].max, target.origin.y]
        }
    end
  end

  dragger.when_tapped do
    startX = target.origin.x
    elasticity = 0.5
    animations = [[0.1, 5, UIViewAnimationOptionCurveEaseOut],
                  [0.1, 0, UIViewAnimationOptionCurveEaseIn],
                  [0.1 * elasticity, 5 * elasticity, UIViewAnimationOptionCurveEaseOut],
                  [0.1 * elasticity, 0, UIViewAnimationOptionCurveEaseIn],
                  [0.1 * elasticity * elasticity, 5 * elasticity * elasticity, UIViewAnimationOptionCurveEaseOut],
                  [0.1 * elasticity * elasticity, 0, UIViewAnimationOptionCurveEaseIn]]
    step = Proc.new do
      dur, dx, options = animations.shift
      UIView.animateWithDuration dur, delay:0, options:options,
        animations: lambda { target.origin = [startX + dx, target.origin.y] },
        completion: lambda { |finished| step.call if animations.any? }
    end
    step.call #unless dragging
  end
end

def addResizer(dragger, options={})
  target = dragger.superview
  initialSize = nil
  fudge = 21
  dragger.userInteractionEnabled = true
  dragger.when_panned do |recognizer|
    pt = recognizer.translationInView(target.superview)
    case recognizer.state
    when UIGestureRecognizerStateBegan
      initialSize = target.size
    when UIGestureRecognizerStateChanged
      target.size = [[initialSize.width + pt.x, options[:minWidth] || 0].max, target.size.height]
      dragger.origin = [target.size.width - dragger.size.width + fudge, dragger.origin.y]
    when UIGestureRecognizerStateEnded
      factor = options[:factor] || 1
      width = (target.size.width / factor).round * factor
      UIView.animateWithDuration 0.1,
        animations: lambda {
          target.size = [[width, options[:minWidth] || 0].max, target.size.height]
          dragger.origin = [target.size.width - dragger.size.width + fudge, dragger.origin.y]
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
