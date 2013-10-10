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
    fudge = 70
    @scrollView.frame = self.view.bounds
    @scrollView.contentSize = CGSizeMake(@scrollView.frame.size.width, @scrollView.frame.size.height + fudge)

    self.view.stylesheet = :sitters
    self.view.stylename = :sitters

    today = NSDate.date.dateAtStartOfDay
    self.selectedTimeSpan = TimeSpan.new(today, 18, 21)
  end

  layout do
    view.styleId = :sitters

    mySittersController = MySittersController.alloc.init
    mySittersController.outerController = self
    self.addChildViewController mySittersController
    @mySittersView = mySittersController.view

    observe(self, :selectedTimeSpan) do mySittersController.selectedTimeSpan = selectedTimeSpan end

    @navigationController = UINavigationController.alloc.initWithRootViewController(mySittersController)
    @navigationController.delegate = self
    # mySittersController.view.frame = [[0, 140], [320, 700]]
    # nav.navigationItem.titleView.setHidden true

    @scrollView = subview UIScrollView.alloc.initWithFrame(self.view.bounds) do
      subview @navigationController.view, size: [320, 700]
    end

    createTimeSelector
  end

  # def navigationController(c1, willShowViewController:c2, animated:f); puts 'navigationController'; end
  # def navigationController(c1, didShowViewController:c2, animated:f); puts 'navigationController'; end

  def presentAddSitterView
    # puts "presentAddSitterView"
    @suggestedSittersController ||= SuggestedSittersController.alloc.init
    @navigationController.pushViewController @suggestedSittersController, animated:true
    # self.wantsFullScreenLayout = true
    # UIApplication.sharedApplication.setStatusBarHidden true
    UIView.animateWithDuration 0.3,
      animations: lambda { setTimeSelectorHeight :short },
      completion: lambda { |finished| @scrollView.contentOffset = CGPointZero;  setTimeSelectorHeight :force_short }
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

  layout do
    view.styleId = :sitters

    createSitterAvatars

    subview UIButton, styleId: :recommended, styleClass: :big_button do
      label = subview UILabel, text: 'View Recommended'
      label.when_tapped { outerController.presentAddSitterView }
      subview UILabel, styleClass: :caption, text: '14 connected sitters'
    end

    subview UIButton, styleId: :invite, styleClass: :big_button do
      subview UILabel, text: 'Invite a Sitter'
      subview UILabel, styleClass: :caption, text: 'to add a sitter you know'
    end

    sitterCount = 2
    toSevenString = NSNumberFormatter.alloc.init.setNumberStyle(NSNumberFormatterSpellOutStyle).stringFromNumber(7 - sitterCount)
    addSittersLabel = subview UILabel, styleId: :add_sitters, text: "Add #{toSevenString} more sitters"
    addSittersLabel.when_tapped { outerController.presentAddSitterView }
    subview UILabel, styleId: :add_sitters_caption, text: 'to enjoy complete freedom and spontaneity.'

    # observe self, :sitters do
    #   puts "sitters"
    #   puts "#{sitters.length}"
    # end
  end

  def viewWillAppear(animated)
    outerController.mySittersWillAppear if outerController
  end

  def createSitterAvatars
    self.sitters = Sitter.added
    sitterViews = []
    view = subview UIView, styleId: :avatars, left: 10, top: 150, width: 300, height: 300 do
      for i in 0...7
        sitter = sitters[i]
        view = subview SitterCircle, sitter: sitter, styleClass: 'sitter' do
          subview UILabel, text: (i+1).to_s
        end
        # view.when_tapped { puts 'tap sitter' }
        # view.when_tapped { presentAddSitterView }
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
