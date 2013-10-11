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
    @suggestedSittersController ||= SuggestedSittersController.alloc.init.tap do |controller| controller.outerController = self end
    # @suggestedSittersController.title = 'Recommended Sitters'
    @navigationController.pushViewController @suggestedSittersController, animated:true
    # self.wantsFullScreenLayout = true
    # UIApplication.sharedApplication.setStatusBarHidden true

    UIView.animateWithDuration 0.3,
      animations: lambda { setTimeSelectorHeight :short }
  end

  def presentSitterDetails(sitter)
    @sitterDetailsController ||= SitterDetailsController.alloc.init
    @sitterDetailsController.sitter = sitter
    # @sitterDetailsController.title = sitter.name
    @navigationController.pushViewController @sitterDetailsController, animated:true
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

      viewRecommended = subview UIButton, styleId: :recommended, styleClass: :big_button do
        label = subview UILabel, text: 'View Recommended'
        label.when_tapped { outerController.presentSuggestedSitters }
        caption = subview UILabel, styleClass: :caption, text: "#{Sitter.all.length} connected sitters"
        caption.when_tapped { outerController.presentSuggestedSitters }
      end
      # viewRecommended.when_tapped { '2 outerController.presentSuggestedSitters' }

      subview UIButton, styleId: :invite, styleClass: :big_button do
        subview UILabel, text: 'Invite a Sitter'
        subview UILabel, styleClass: :caption, text: 'to add a sitter you know'
      end

      sitterCount = 2
      toSevenString = NSNumberFormatter.alloc.init.setNumberStyle(NSNumberFormatterSpellOutStyle).stringFromNumber(7 - sitterCount)
      addSittersLabel = subview UILabel, styleId: :add_sitters, text: "Add #{toSevenString} more sitters"
      addSittersLabel.when_tapped { outerController.presentSuggestedSitters }
      subview UILabel, styleId: :add_sitters_caption, text: 'to enjoy complete freedom and spontaneity.'

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
    view = subview UIView, styleId: :avatars, origin: [0, 88], size: [300, 300] do
      for i in 0...7
        sitter = sitters[i]
        view = subview SitterCircle, sitter: sitter, styleClass: 'sitter' do
          subview UILabel, text: (i+1).to_s
        end
        # view.when_tapped { puts 'tap sitter' }
        # view.when_tapped { presentSuggestedSitters }
        sitterViews << view
      end
    end
    HexagonLayout.new.applyTo sitterViews

    observe(self, :selectedTimeSpan) do |_, timeSpan|
      UIView.animateWithDuration 0.3,
        animations: lambda {
          sitterViews.map do |view|
            alpha = if view.sitter.availableAt(timeSpan) then 1 else 0.5 end
            view.alpha = alpha unless view.alpha == alpha
          end
        }
      end

    return view
  end
end

Teacup::Stylesheet.new :sitters do
  style :right_dragger,
    left: '100%-20',
    top: 0,
    width: 40,
    height: '100%'
end
