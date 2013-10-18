class BookingController < UIViewController
  include BW::KVO
  stylesheet :booking
  attr_reader :timeSelectionController, :mySittersController, :suggestedSittersController

  def initWithNibName(name, bundle:bundle)
    super
    self.tap do
      self.tabBarItem = UITabBarItem.alloc.initWithTitle('Sitters', image:UIImage.imageNamed('tabs/sitters'), tag:1)
    end
  end

  def viewDidLoad
    super
    self.view.stylename = :sitters
    mySittersController.timeSelection = timeSelectionController.timeSelection
  end

  layout do
    @mySittersController = SittersController.alloc.init
    @mySittersController.delegate = self

    @navigationController = UINavigationController.alloc.initWithRootViewController(mySittersController)
    @navigationController.delegate = self

    subview @navigationController.view

    @timeSelectionController = TimeSelectionController.alloc.init
    @timeSelectionController.delegate = self
    subview @timeSelectionController.view
  end

  def timeSelectionChanged(timeSelection)
    mySittersController.timeSelection = timeSelection
  end

  def navigationController(navigationController, willShowViewController:targetController, animated:flag)
    UIView.animateWithDuration 0.3, animations: lambda {
      timeSelectionController.setHeight targetController == mySittersController ? :tall : :short
    }
  end

  def presentSuggestedSitters
    TestFlight.passCheckpoint 'Suggested sitters'
    @suggestedSittersController ||= SuggestedSittersController.alloc.init.tap do |controller| controller.outerController = self end
    # @suggestedSittersController.title = 'Suggested Sitters'
    @navigationController.pushViewController @suggestedSittersController, animated:true
  end

  def presentSitterDetails(sitter)
    TestFlight.passCheckpoint "Sitter details: #{sitter.name}"
    @sitterDetailsController ||= SitterDetailsController.alloc.init
    @sitterDetailsController.sitter = sitter
    # @sitterDetailsController.title = sitter.name
    @navigationController.pushViewController @sitterDetailsController, animated:true
  end
end
