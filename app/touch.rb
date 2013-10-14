module TouchUtils
  def self.dragOnTouch(target, handle:dragger, options:options)
    xMin = options[:xMinimum] || 0
    minWidth = options[:widthMinimum] || 0
    factor = options[:widthFactor] || 1
    resize = options[:resize] || false
    initialOrigin = nil
    initialSize = nil
    animator = nil
    attachmentBehavior = nil
    dragger.userInteractionEnabled = true
    dragger.when_panned do |recognizer|
      pt = recognizer.translationInView(target.superview)

      case recognizer.state
      when UIGestureRecognizerStateBegan
        initialOrigin = target.origin
        initialSize = target.size
        # animator ||= UIDynamicAnimator.alloc.initWithReferenceView(target.superview)
        # animator.removeAllBehaviors

      when UIGestureRecognizerStateChanged
        # target.tx = pt.x

        x = [initialOrigin.x + pt.x, xMin].max
        x = [x, 320 - target.size.width / 2].min
        x = [x, initialOrigin.x + initialSize.width - minWidth].min if resize
        target.x = x
        target.width = initialOrigin.x + initialSize.width - x if resize

      when UIGestureRecognizerStateEnded
        # dragger.isDragging = false

        x = ((target.origin.x - xMin) / factor).round * factor + xMin
        x = [x, xMin].max
        x = [x, initialOrigin.x + initialSize.width - minWidth].min if resize

        # itemBehavior = UIDynamicItemBehavior.alloc.initWithItems([target])
        # itemBehavior.allowsRotation = false
        # itemBehavior.density = target.size.width * target.size.height / 3000
        # animator.addBehavior itemBehavior

        # snapBehavior = UISnapBehavior.alloc.initWithItem(target, snapToPoint:[x + target.center.x - target.origin.x, target.center.y])
        # animator.addBehavior(snapBehavior)

        UIView.animateWithDuration 0.1,
          animations: lambda {
            # target.tx = 0
            target.x = x
            target.width = initialOrigin.x + initialSize.width - x if resize
          }
      end
    end
  end

  def self.resizeOnTouch(target, handle:dragger, options:options)
    xMin = options[:xMinimum] || 0
    minWidth = options[:widthMinimum] || 0
    factor = options[:widthFactor] || 1
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
        width = (target.width / factor).round * factor
        UIView.animateWithDuration 0.1,
          animations: lambda {
            target.width = [width, minWidth].max
            dragger.x = target.width - dragger.width + fudge
          }
      end
    end
  end

  def self.bounceOnTap(target, handle:view)
    view.when_tapped do
      initialX = target.x
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
          animations: lambda { target.x = initialX + dx },
          completion: lambda { |finished| step.call if animations.any? }
      end
      step.call
    end
  end
end
