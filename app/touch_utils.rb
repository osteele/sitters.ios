module TouchUtils
  # Attach a pan recognizer to `handle` that drags `target` horizontally.
  # If òptions[:resize]`, the target is simultaneously resized, such that its right edge stays at position.
  # `target` is assumed to be a subview of `target` (so that `target.origin` is modified, but `handle.origin` is not).
  def self.dragOnTouch(target, handle:dragger, options:options)
    xMin = options[:xMinimum] || 0
    xMax = options[:xMaximum]
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
        x = initialOrigin.x + pt.x
        x = [x, xMin].max
        x = [x, 320 - target.size.width / 2].min
        x = [x, initialOrigin.x + initialSize.width - minWidth].min if resize
        target.x = x
        target.width = initialOrigin.x + initialSize.width - x if resize

      when UIGestureRecognizerStateEnded
        x = ((target.origin.x - xMin) / factor).round * factor + xMin
        x = [x, xMin].max
        x = [x, xMax].min if xMax
        x = [x, initialOrigin.x + initialSize.width - minWidth].min if resize

        # itemBehavior = UIDynamicItemBehavior.alloc.initWithItems([target])
        # itemBehavior.allowsRotation = false
        # itemBehavior.density = target.size.width * target.size.height / 3000
        # animator.addBehavior itemBehavior

        # snapBehavior = UISnapBehavior.alloc.initWithItem(target, snapToPoint:[x + target.center.x - target.origin.x, target.center.y])
        # animator.addBehavior(snapBehavior)

        showDraggableState target, began:false, animated:true
        UIView.animateWithDuration 0.1,
          animations: -> {
            target.x = x
            target.width = initialOrigin.x + initialSize.width - x if resize
          }
      end
    end
  end

  # Attach a pan recognizer to `handle` that resizes `target` horizontally.
  # `target` is assumed to be a subview of `target` (so that `target.size` is modified, but `handle.origin` is not).
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
        # dragger.x = target.width - dragger.width + fudge
      when UIGestureRecognizerStateEnded
        width = (target.width / factor).round * factor
        showDraggableState target, began:false, animated:true
        UIView.animateWithDuration 0.1,
          animations: -> {
            target.width = [width, minWidth].max
            dragger.x = target.width - dragger.width + fudge
          }
      end
    end
  end

  # Attach a pan recognizer to `handle` that resizes `target` horizontally.
  # `target` is assumed to be a subview of `target` (so that `target.size` is modified, but `handle.origin` is not).
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

      showDraggableState target, began:false, animated:false

      # delay = 0
      # for duration, dx, options in animations
      #   UIView.animateWithDuration duration, delay:delay, options:options,
      #     animations: -> { target.tx = dx },
      #     completion: -> _ {}
      #   delay += duration
      # end

      step = Proc.new do
        dur, dx, options = animations.shift
        UIView.animateWithDuration dur, delay:0, options:options,
          # TODO should this modify the transform instead of the origin?
          animations: -> { target.tx = dx },
          completion: -> finished { step.call if animations.any? }
      end
      step.call
    end
  end

  def self.showDraggableState(target, began:began, animated:animated)
    if animated
      UIView.animateWithDuration 0.1, animations: -> { showDraggableState(target, began:began, animated:false) }
      return
    end
    scale = began ? 1.05 : 1
    target.alpha = began ? 0.8 : 1
    target.transform = CGAffineTransformMakeScale(scale, scale)
  end
end
