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

    mySittersController = SittersController.alloc.init
    mySittersController.outerController = self
    observe(self, :selectedTimeSpan) do mySittersController.selectedTimeSpan = selectedTimeSpan end

    @navigationController = UINavigationController.alloc.initWithRootViewController(mySittersController)
    @navigationController.delegate = self

    subview @navigationController.view #, size: [320, 1000]

    createTimeSelector
  end

  # def navigationController(c1, willShowViewController:c2, animated:f); puts 'navigationController'; end
  # def navigationController(c1, didShowViewController:c2, animated:f); puts 'navigationController'; end

  def presentSuggestedSitters
    TestFlight.passCheckpoint 'Suggested sitters'
    @suggestedSittersController ||= SuggestedSittersController.alloc.init.tap do |controller| controller.outerController = self end
    # @suggestedSittersController.title = 'Suggested Sitters'
    @navigationController.pushViewController @suggestedSittersController, animated:true
    UIView.animateWithDuration 0.3, animations: lambda { setTimeSelectorHeight :short }
  end

  def presentSitterDetails(sitter)
    TestFlight.passCheckpoint "Sitter details: #{sitter.name}"
    @sitterDetailsController ||= SitterDetailsController.alloc.init
    @sitterDetailsController.sitter = sitter
    # @sitterDetailsController.title = sitter.name
    @navigationController.pushViewController @sitterDetailsController, animated:true
    UIView.animateWithDuration 0.3, animations: lambda { setTimeSelectorHeight :short }
  end

  def mySittersWillAppear
    UIView.animateWithDuration 0.3, animations: lambda { setTimeSelectorHeight :tall }
  end
end
