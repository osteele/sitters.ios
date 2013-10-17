class SittersController < UIViewController
  include BW::KVO
  stylesheet :sitters
  attr_accessor :delegate
  attr_accessor :timeSelection
  attr_accessor :sitters

  def viewDidLoad
    super

    fudge = 10
    @scrollView.frame = self.view.bounds
    @scrollView.contentSize = CGSizeMake(@scrollView.frame.size.width, @scrollView.frame.size.height + fudge)
  end

  layout do
    view.styleId = :sitters

    @scrollView = subview UIScrollView.alloc.initWithFrame(self.view.bounds) do

      createSitterAvatars

      viewRecommended = subview UIButton.buttonWithType(UIButtonTypeRoundedRect), :big_button, styleId: :recommended, styleClass: :big_button do
        label = subview UILabel, text: 'View Recommended', userInteractionEnabled: false
        caption = subview UILabel, styleClass: :caption, text: "#{Sitter.all.length} connected sitters", userInteractionEnabled: false
      end
      viewRecommended.when_tapped { delegate.presentSuggestedSitters }

      subview UIButton.buttonWithType(UIButtonTypeRoundedRect), styleId: :invite, styleClass: :big_button do
        subview UILabel, text: 'Invite a Sitter'
        subview UILabel, styleClass: :caption, text: 'to add a sitter you know'
      end

      addSittersLabel = subview UILabel, styleId: :add_sitters
      addSittersCaption = subview UILabel, styleId: :add_sitters_caption, text: 'to enjoy complete freedom and spontaneity.'
      addSittersLabel.when_tapped { delegate.presentSuggestedSitters }

      spellOutFormatter = NSNumberFormatter.alloc.init.setNumberStyle(NSNumberFormatterSpellOutStyle)
      remainingSitterCount = 7 - Sitter.added.length
      toSevenString = spellOutFormatter.stringFromNumber(remainingSitterCount)
      addSittersLabel.text = "Add #{toSevenString} more sitter#{remainingSitterCount == 1 ? '' : 's'}"
      [addSittersLabel, addSittersCaption].each do |v| v.alpha = remainingSitterCount > 0 ? 1 : 0 end

      observe(Sitter, :added) do puts 'Sitter.added' end

      # sittersObserver = NSObject.new
      # class << sittersObserver
      #   def observeValueForKeyPath(keyPath, ofObject:object, change:change, context:context)
      #     puts "fired #{keyPath}"
      #     puts "sitters"
      #     puts "#{sitters.length}"
      #   end
      # end
      # addObserver sittersObserver, forKeyPath: 'sitters', options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld, context:nil

    end

  end

  def createSitterAvatars
    self.sitters = Sitter.added
    sitterViews = []
    view = subview UIView, styleId: :avatars, origin: [0, 88], size: [320, 300] do
      for i in 0...7
        sitter = sitters[i]
        view = subview SitterCircleView, sitter: sitter, labelText: (i+1).to_s, styleClass: :sitter
        view.when_tapped do
          if view.sitter then
            delegate.presentSitterDetails view.sitter
          else
            delegate.presentSuggestedSitters
          end
        end
        sitterViews << view
      end
    end
    HexagonLayout.new.applyTo sitterViews

    observe(self, :timeSelection) do |_, timeSpan|
      UIView.animateWithDuration 0.3,
        animations: lambda {
          sitterViews.map do |view|
            alpha = if not view.sitter or view.sitter.availableAt(timeSpan) then 1 else 0.5 end
            view.alpha = alpha unless view.alpha == alpha
          end
        }
      end

    return view
  end
end
