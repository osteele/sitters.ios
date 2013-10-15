class BookingController < UIViewController
  include BW::KVO
  stylesheet :sitters

  attr_accessor :selectedTimeSpan

  def initWithNibName(name, bundle:bundle)
    super
    self.tap do
      self.tabBarItem = UITabBarItem.alloc.initWithTitle('Sitters', image:UIImage.imageNamed('tabs/sitters.png'), tag:1)
    end
  end

  def viewDidLoad
    super

    self.view.stylesheet = :sitters
    self.view.stylename = :sitters

    today = NSDate.date.dateAtStartOfDay
    self.selectedTimeSpan = TimeSpan.new(today, 18, 21)
  end

  layout do
    view.styleId = :sitters

    mySittersController = MySittersController.alloc.init
    mySittersController.outerController = self
    # mySittersController.title = 'Reserve'
    self.addChildViewController mySittersController
    @mySittersView = mySittersController.view

    observe(self, :selectedTimeSpan) do mySittersController.selectedTimeSpan = selectedTimeSpan end

    @navigationController = UINavigationController.alloc.initWithRootViewController(mySittersController)
    @navigationController.delegate = self
    # mySittersController.view.frame = [[0, 140], [320, 700]]

    subview @navigationController.view, size: [320, 1000]

    createTimeSelector
  end

  # def navigationController(c1, willShowViewController:c2, animated:f); puts 'navigationController'; end
  # def navigationController(c1, didShowViewController:c2, animated:f); puts 'navigationController'; end

  def presentSuggestedSitters
    TestFlight.passCheckpoint 'Suggested sitters'
    @suggestedSittersController ||= SuggestedSittersController.alloc.init.tap do |controller| controller.outerController = self end
    @navigationController.pushViewController @suggestedSittersController, animated:true
    UIView.animateWithDuration 0.3, animations: lambda { setTimeSelectorHeight :short }
  end

  def presentSitterDetails(sitter)
    TestFlight.passCheckpoint "Sitter details: #{sitter.name}"
    @sitterDetailsController ||= SitterDetailsController.alloc.init
    @sitterDetailsController.sitter = sitter
    @navigationController.pushViewController @sitterDetailsController, animated:true
    UIView.animateWithDuration 0.3, animations: lambda { setTimeSelectorHeight :short }
  end

  def mySittersWillAppear
    UIView.animateWithDuration 0.3, animations: lambda { setTimeSelectorHeight :tall }
  end
end

class MySittersController < UIViewController
  include BW::KVO
  stylesheet :sitters
  attr_accessor :outerController
  attr_accessor :selectedTimeSpan
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
      viewRecommended.when_tapped { outerController.presentSuggestedSitters }

      subview UIButton.buttonWithType(UIButtonTypeRoundedRect), styleId: :invite, styleClass: :big_button do
        subview UILabel, text: 'Invite a Sitter'
        subview UILabel, styleClass: :caption, text: 'to add a sitter you know'
      end

      addSittersLabel = subview UILabel, styleId: :add_sitters
      addSittersCaption = subview UILabel, styleId: :add_sitters_caption, text: 'to enjoy complete freedom and spontaneity.'
      addSittersLabel.when_tapped { outerController.presentSuggestedSitters }

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

  def viewWillAppear(animated)
    outerController.mySittersWillAppear if outerController
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
            outerController.presentSitterDetails view.sitter
          else
            outerController.presentSuggestedSitters
          end
        end
        sitterViews << view
      end
    end
    HexagonLayout.new.applyTo sitterViews

    observe(self, :selectedTimeSpan) do |_, timeSpan|
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

Teacup::Stylesheet.new :sitters do
  style :hours_bar,
    backgroundColor: UIColor.whiteColor,
    left: 10,
    top: 75;

  style :right_dragger,
    left: '100%-20',
    top: 0,
    width: 40,
    height: '100%'
end
