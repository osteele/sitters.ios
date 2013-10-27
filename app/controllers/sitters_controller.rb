class SittersController < UIViewController
  include BW::KVO
  GridCount = 7

  attr_accessor :delegate
  attr_accessor :timeSelection
  attr_accessor :sitters

  # stylesheet :sitters
  def stylesheet
    Teacup::Stylesheet[:sitters]
  end

  def viewDidLoad
    super

    navBarHeight = 60
    contentHeight = @scrollView.subviews.map(&:bottom).max
    @scrollView.contentSize = CGSizeMake(@scrollView.frame.size.width, contentHeight + navBarHeight)
    sitterControllers.each(&:viewDidLoad)
  end

  layout do
    view.stylename = :sitters

    @scrollView = subview UIScrollView.alloc.initWithFrame(self.view.bounds), :scroll do
      createSitterAvatars

      viewRecommended = subview UIButton.buttonWithType(UIButtonTypeRoundedRect), :recommended_sitters_button, do
        label = subview UILabel, :big_button_label, text: 'View Recommended', userInteractionEnabled: false
        caption = subview UILabel, :big_button_caption, text: "#{Sitter.all.length} connected sitters", userInteractionEnabled: false
      end
      viewRecommended.when_tapped { delegate.presentSuggestedSitters }

      subview UIButton.buttonWithType(UIButtonTypeRoundedRect), :invite_sitter_button, do
        subview UILabel, :big_button_label, text: 'Invite a Sitter'
        subview UILabel, :big_button_caption, text: 'to add a sitter you know'
      end

      addSittersLabel = subview UILabel, :add_sitters_text
      addSittersCaption = subview UILabel, :add_sitters_caption
      addSittersLabel.when_tapped { delegate.presentSuggestedSitters }

      spellOutFormatter = NSNumberFormatter.alloc.init.setNumberStyle(NSNumberFormatterSpellOutStyle)

      updateAddSitterText = lambda do
        sitters = Family.instance.sitters
        remainingSitterCount = 7 - sitters.length
        toSevenString = spellOutFormatter.stringFromNumber(remainingSitterCount)
        pl = remainingSitterCount == 1 ? '' : 's'
        addSittersLabel.text = "Add #{toSevenString} more sitter#{pl}"
        [addSittersLabel, addSittersCaption].each do |v| v.alpha = remainingSitterCount == 0 ? 0 : 1 end
      end
      observe(Family.instance, :sitters) do updateAddSitterText.call end
      updateAddSitterText.call
    end
  end

  private

  attr_reader :sitterControllers

  def updateSitterAvailability
    sitterControllers.each do |controller|
      sitter = controller.sitter
      controller.available = sitter && timeSelection && sitter.availableAt(timeSelection)
    end
  end

  def createSitterAvatars
    self.sitters = Family.instance.sitters
    @sitterControllers = []
    sitterViews = []
    subview UIView, :avatars do
      for i in 0...GridCount
        sitter = sitters[i]
        controller = SitterCircleController.alloc.initWithSitter(sitter, labelString:(i+1).to_s)
        view = subview controller.view, :sitter, width: 90, height: 90
        view.when_tapped do
          if controller.sitter then
            delegate.presentDetailsForSitter controller.sitter
          else
            delegate.presentSuggestedSitters
          end
        end
        @sitterControllers << controller
        sitterViews << view
      end
    end

    HexagonLayout.new.applyTo sitterViews
    updateSitterAvailability

    observe(Family.instance, :sitters) do
      sitters = Family.instance.sitters
      sitterControllers.each_with_index do |view, i|
        view.sitter = sitters[i]
      end
      updateSitterAvailability
    end

    observe(self, :timeSelection) do
      @timeSelection = timeSelection
      UIView.animateWithDuration 0.3, animations: lambda { updateSitterAvailability }
    end
  end
end
