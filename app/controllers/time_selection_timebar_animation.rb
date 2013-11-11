class TimeSelectionController < UIViewController

  private

  # Animation Constants
  SlowAnimationFactor = 1
  HeightModeAnimationSeconds = 0.5 * SlowAnimationFactor
  HeightModeFastAnimationSeconds = 0.2 * SlowAnimationFactor
  ShortViewHeight = 55
  ShortViewTop = 64


  #
  # Animation between Interactive and Summary mode
  #

  public

  def setMode(key, animated:animated)
    @heightMode ||= :interactive
    return if @heightMode == key
    @heightMode = key

    slowAnimationScale = NSUserDefaults.standardUserDefaults['slowAnimation'] ? 10 : 1

    view = self.view
    case key
    when :summary
      # initial state -- outside the animation
      summaryViewHoursLabel.frame = summaryViewHoursLabelFg.frame = [[0, 18], [320, 35]]
      # summaryViewHoursLabel.textAlignment = NSTextAlignmentCenter
      summaryViewHoursLabel.tx = summaryViewHoursLabelFg.tx = hoursIndicator.center.x - summaryViewHoursLabel.center.x
      summaryViewHoursLabel.ty = summaryViewHoursLabelFg.ty = hoursIndicator.center.y - summaryViewHoursLabel.center.y
      summaryViewHoursLabel.alpha = summaryViewHoursLabelFg.alpha = 1
      summaryViewHoursLabelFg.textColor = '#5481C9'.to_color
      hourRangeLabel.hidden = true

      # set these before saveInteractiveModeViewProperties, so we animate *back* to them later
      saveInteractiveModeViewProperties

      # quickly
      UIView.animateWithDuration HeightModeFastAnimationSeconds * slowAnimationScale, animations: -> {
        getViewsForMode(:interactive).each { |v| v.alpha = 0 }
        summaryViewHoursLabelFg.alpha = 0
        # hoursIndicator.top = summaryViewHoursLabel.top
      }

      # slowly
      UIView.animateWithDuration HeightModeAnimationSeconds * slowAnimationScale, animations: -> {
        getViewsForMode(:summary).each { |v| v.alpha = 1 }
        summaryViewHoursLabelFg.alpha = 0
        view.frame = [[view.x, ShortViewTop], [view.width, ShortViewHeight]]
        summaryViewHoursLabel.transform = summaryViewHoursLabelFg.transform = summaryViewHoursLabel.transform.tap { |t| t.tx = t.ty = 0 }
      }, completion: ->_ { updateGradientFrame }

      view.layer.masksToBounds = true

      # animation = CABasicAnimation.animationWithKeyPath('bounds.size.height')
      # animation.duration = HeightModeAnimationSeconds * slowAnimationScale
      # animation.timingFunction = CAMediaTimingFunction.functionWithName(KCAMediaTimingFunctionEaseInEaseOut)
      # animation.toValue = ShortViewHeight
      # gradientLayer = view.instance_variable_get(:@teacup_gradient_layer)
      # gradientLayer.removeAllAnimations
      # gradientLayer.addAnimation animation, forKey:nil
      # view.layer.contentsGravity = KCAGravityTop

    when :interactive
      totalAnimationDuration = HeightModeAnimationSeconds * slowAnimationScale
      rapidStageAnimationDuration = HeightModeFastAnimationSeconds * slowAnimationScale

      UIView.animateWithDuration totalAnimationDuration, animations: -> {
        restoreInteractiveModeViewProperties view
        restoreInteractiveModeViewProperties summaryViewHoursLabel, :frame
        restoreInteractiveModeViewProperties summaryViewHoursLabelFg, :frame
        updateGradientFrame
      }

      UIView.animateWithDuration rapidStageAnimationDuration,
        delay: totalAnimationDuration - rapidStageAnimationDuration,
        options: 0,
        animations: -> {
          restoreInteractiveModeViewProperties
        }, completion: ->_ {
          summaryViewHoursLabel.alpha = 0
          summaryViewHoursLabelFg.alpha = 0
          hourRangeLabel.hidden = false
        }

      # animation = CABasicAnimation.animationWithKeyPath('bounds.size.height')
      # animation.duration = HeightModeAnimationSeconds * slowAnimationScale
      # animation.timingFunction = CAMediaTimingFunction.functionWithName(KCAMediaTimingFunctionEaseInEaseOut)
      # animation.toValue = 20
      # animation.removedOnCompletion = true
      # gradientLayer = view.instance_variable_get(:@teacup_gradient_layer)
      # gradientLayer.removeAllAnimations
      # gradientLayer.addAnimation animation, forKey:nil
    end

  end

  private

  def updateGradientFrame
    gradientLayer = view.instance_variable_get(:@teacup_gradient_layer)
    gradientLayer.frame = view.bounds if gradientLayer
  end

  def declareViewMode(mode, view)
    getViewsForMode(mode) << view
  end

  def getViewsForMode(mode)
    raise "Unknown mode #{mode}" unless [:interactive, :summary].include?(mode)
    @viewsForMode ||= {}
    @viewsForMode[mode] ||= []
  end

  def saveInteractiveModeViewProperties
    saveFrameViews = [view, dayIndicator, hoursIndicator, summaryViewHoursLabel, summaryViewHoursLabelFg]
    saveAlphaViews = getViewsForMode(:interactive) + getViewsForMode(:summary)
    @savedTimeSelectorValues ||= {
      alpha: saveAlphaViews.map { |v| [v, v.alpha, false] },
      frame: saveFrameViews.map { |v| [v, v.frame, false] }
    }
  end

  def restoreInteractiveModeViewProperties(onlyView=nil, onlyProperty=nil)
    savedProperties = @savedTimeSelectorValues
    for propertyName, mappings in savedProperties
      for item in mappings
        view, propertyValue, fired = item
        next if fired
        next unless view == onlyView or onlyView.nil?
        next unless propertyName == onlyProperty or onlyProperty.nil?
        view.send :"#{propertyName}=", propertyValue
        item[2] = true
      end
    end
    @savedTimeSelectorValues = nil if onlyView.nil? and onlyProperty.nil?
  end
end
