class BookingController < UIViewController
  include BW::KVO
  stylesheet :booking

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
    @mySittersController = SittersController.alloc.init.tap do |c| c.delegate = self end
    @navigationController = UINavigationController.alloc.initWithRootViewController(mySittersController).tap do |c| c.delegate = self end
    @timeSelectionController = TimeSelectionController.alloc.init.tap do |c| c.delegate = self end

    subview @navigationController.view
    subview @timeSelectionController.view
  end

  def timeSelectionChanged(timeSelection)
    mySittersController.timeSelection = timeSelection
  end

  def navigationController(navigationController, willShowViewController:targetController, animated:flag)
    mode = targetController == mySittersController ? :interactive : :summary
    timeSelectionController.setMode mode, animated:true
  end

  def presentSuggestedSitters
    TestFlight.passCheckpoint 'Suggested sitters'
    navigationController.pushViewController suggestedSittersController, animated:true
  end

  def presentDetailsForSitter(sitter)
    TestFlight.passCheckpoint "Sitter details: #{sitter.name}"
    sitterDetailsController.sitter = sitter
    sitterDetailsController.action = case
      when Sitter.canAdd(sitter) then :add
      when sitter.availableAt(timeSelectionController.timeSelection) then :reserve
      else :request
      end
    navigationController.pushViewController sitterDetailsController, animated:true
  end

  def action(action, sitter:sitter)
    msg = case action
      when :add then "We’ve just sent a request to add %s to your Seven Sitters. We’ll let you know when she confirms."
      when :reserve then "%s will babysit for you at the specified time."
      when :request then "We’ve just sent a request to %s. We’ll let you know whether she’s available."
    end

    sitterActionDelegate = SitterActionDelegate.new(sitter:sitter, action:action, delegate:self)
    @actionDelegates ||= []
    @actionDelegates << sitterActionDelegate

    UIAlertView.alloc.initWithTitle('Request Sent',
      message:msg % sitter.firstName,
      delegate:sitterActionDelegate,
      cancelButtonTitle:'OK',
      otherButtonTitles:nil).show
  end

  def actionDelegateDidComplete(sitterActionDelegate)
    @actionDelegates -= [sitterActionDelegate]
  end

  private

  def navigationController; @navigationController; end
  attr_reader :timeSelectionController
  attr_reader :mySittersController

  def sitterDetailsController
    @sitterDetailsController ||= SitterDetailsController.alloc.init.tap do |controller| controller.delegate = self end
  end

  def suggestedSittersController
    @suggestedSittersController ||= SuggestedSittersController.alloc.init.tap do |controller| controller.delegate = self end
  end
end

class SitterActionDelegate
  attr_reader :sitter, :action, :delegate

  def initialize(options)
    @sitter = options[:sitter]
    @action = options[:action]
    @delegate = options[:delegate]
  end

  def alertView(alertView, clickedButtonAtIndex:index)
    return unless action == :add
    Scheduler.after 10 do
      Sitter.addSitter sitter
      delegate.actionDelegateDidComplete self
      UIAlertView.alloc.initWithTitle('Sitter Confirmed',
        message:"%s has accepted your request. We’ve added her to your Seven Sitters." % sitter.firstName,
        delegate:nil,
        cancelButtonTitle:'OK',
        otherButtonTitles:nil).show
    end
  end
end
