class SittersController < UIViewController
  include BW::KVO
  attr_accessor :delegate
  attr_accessor :timeSelection
  attr_accessor :sitters

  # stylesheet :sitters
  def stylesheet
    Teacup::Stylesheet[:sitters]
  end

  def viewDidLoad
    super

    fudge = 10
    # @scrollView.frame = self.view.bounds
    @scrollView.contentSize = CGSizeMake(@scrollView.frame.size.width, @scrollView.frame.size.height + fudge)
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
        sitters = Sitter.added
        remainingSitterCount = 7 - Sitter.added.length
        toSevenString = spellOutFormatter.stringFromNumber(remainingSitterCount)
        pl = remainingSitterCount == 1 ? '' : 's'
        addSittersLabel.text = "Add #{toSevenString} more sitter#{pl}"
        [addSittersLabel, addSittersCaption].each do |v| v.alpha = remainingSitterCount == 0 ? 0 : 1 end
      end
      observe(Sitter, :added) do updateAddSitterText.call end
      updateAddSitterText.call
    end
  end

  private

  attr_reader :sitterViewControllers

  def updateSitterAvailability
    sitterViewControllers.each do |controller|
      sitter = controller.sitter
      controller.available = sitter && timeSelection && sitter.availableAt(timeSelection)
    end
  end

  def createSitterAvatars
    self.sitters = Sitter.added
    @sitterViewControllers = []
    sitterViews = []
    subview UIView, :avatars do
      for i in 0...7
        sitter = sitters[i]
        controller = SitterCircleController.alloc.initWithSitter(sitter, labelString:(i+1).to_s)
        addChildViewController controller
        view = subview controller.view, :sitter, width: 90, height: 90
        controller.didMoveToParentViewController self
        view.when_tapped do
          if view.sitter then
            delegate.presentSitterDetails view.sitter
          else
            delegate.presentSuggestedSitters
          end
        end
        @sitterViewControllers << controller
        sitterViews << view
      end
    end

    HexagonLayout.new.applyTo sitterViews
    updateSitterAvailability

    observe(Sitter, :added) do
      sitters = Sitter.added
      sitterViewControllers.each_with_index do |view, i|
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
