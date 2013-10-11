NSNumberFormatterSpellOutStyle = 5 unless Object.const_defined?(:NSNumberFormatterSpellOutStyle)

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
  initialPosition = nil
  animator = nil
  attachment = nil
  dragger.userInteractionEnabled = true
  dragger.when_panned do |recognizer|
    pt = recognizer.translationInView(target.superview)

    case recognizer.state
    when UIGestureRecognizerStateBegan
      initialPosition = target.origin

      animator ||= UIDynamicAnimator.alloc.initWithReferenceView(target.superview)
      animator.removeAllBehaviors

      # attachment ||= UIAttachmentBehavior.alloc.initWithItem(target, attachedToAnchor:[pt.x + target.size.width / 2, pt.y + target.size.height / 2])
      # animator.addBehavior(attachment)
      # collision = UICollisionBehavior.alloc.initWithItems []
      # collision.addBoundaryWithIdentifier(:leftWall, fromPoint: [50, 0], toPoint: [50, 1000])
      # animator.addBehavior(collision)

    when UIGestureRecognizerStateChanged
      # center = [[initialPosition.x + pt.x, options[:min] || 0].max, target.origin.y]
      # center[0] += target.size.width / 2
      # center[1] += target.size.height / 2
      # attachment.anchorPoint = center
      target.origin = [[initialPosition.x + pt.x, options[:min] || 0].max, target.origin.y]

    when UIGestureRecognizerStateEnded
      min = options[:min] || 0
      factor = options[:factor] || 1
      x = ((target.origin.x - min) / factor).round * factor + min

      center = [[x, options[:min] || 0].max, target.origin.y]
      center[0] += target.size.width / 2
      center[1] += target.size.height / 2
      snapBehavior = UISnapBehavior.alloc.initWithItem(target, snapToPoint:center)
      animator.removeAllBehaviors
      animator.addBehavior(snapBehavior)

      # UIView.animateWithDuration 0.1,
      #   animations: lambda {
      #     target.origin = [[x, options[:min] || 0].max, target.origin.y]
      #   }
    end
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
