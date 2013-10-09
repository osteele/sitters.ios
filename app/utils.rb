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
  # class << dragger
  #   def target; self.superview; end

  #   def touchesBegan(touches, withEvent:event)
  #     @initialOrigin = target.origin
  #     @initialTouchPoint = touches.anyObject.locationInView(target.superview)
  #   end

  #   def touchesMoved(touches, withEvent:event)
  #     touchPoint = touches.anyObject.locationInView(target.superview)
  #     offset = CGPoint.new(touchPoint.x - @initialTouchPoint.x, touchPoint.y - @initialTouchPoint.y)
  #     target.origin = [[0, @initialOrigin.x + offset.x].max, target.origin.y]
  #   end
  # end
  # return

  target = dragger.superview
  initial = nil
  dragger.userInteractionEnabled = true
  dragger.when_panned do |recognizer|
    pt = recognizer.translationInView(target.superview)
    case recognizer.state
    when UIGestureRecognizerStateBegan
      initial = target.origin
    when UIGestureRecognizerStateChanged
      target.origin = [[initial.x + pt.x, options[:min] || 0].max, target.origin.y]
    when UIGestureRecognizerStateEnded
      min = options[:min] || 0
      factor = options[:factor] || 1
      x = ((target.origin.x - min) / factor).round * factor + min
      UIView.animateWithDuration 0.1,
        animations: lambda {
          target.origin = [[x, options[:min] || 0].max, target.origin.y]
        }
    end
  end
end

def addResizer(dragger, options={})
  # class << dragger
  #   def target; self.superview; end

  #   def touchesBegan(touches, withEvent:event)
  #     @initialSize = target.size
  #     @initialTouchPoint = touches.anyObject.locationInView(target.superview)
  #   end

  #   def touchesMoved(touches, withEvent:event)
  #     touchPoint = touches.anyObject.locationInView(target.superview)
  #     offset = CGPoint.new(touchPoint.x - @initialTouchPoint.x, touchPoint.y - @initialTouchPoint.y)
  #     target.size = [[@initialSize.width + offset.x, 100].max, target.size.height]
  #     self.origin = [target.size.width - self.size.width, self.origin.y]
  #   end
  # end
  # return

  dragger.userInteractionEnabled = true
  target = dragger.superview
  initial = nil
  fudge = 21
  dragger.when_panned do |recognizer|
    pt = recognizer.translationInView(target.superview)
    case recognizer.state
    when UIGestureRecognizerStateBegan
      initial = target.size
    when UIGestureRecognizerStateChanged
      target.size = [[initial.width + pt.x, options[:minWidth] || 0].max, target.size.height]
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
