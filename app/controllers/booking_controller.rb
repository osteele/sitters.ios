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
    view.stylename = :sitters
    view.backgroundColor = UIColor.whiteColor
    familySittersController.timeSelection = timeSelectionController.timeSelection
  end

  # def preferredStatusBarStyle; UIStatusBarStyleBlackTranslucent; end

  layout do
    @familySittersController = SittersController.alloc.init.tap do |c| c.delegate = self end
    @navigationController = UINavigationController.alloc.initWithRootViewController(familySittersController).tap do |c| c.delegate = self end
    @timeSelectionController = TimeSelectionController.alloc.init.tap do |c| c.delegate = self end

    subview @navigationController.view
    # subview UIView, :status_bar_background
    subview @timeSelectionController.view

    splash_circle = subview UIView, :splash_circle
    splashAnimationDuration = 0.25
    App.notification_center.observe ApplicationDidLoadDataNotification.name do |notification|
      animation = CABasicAnimation.animationWithKeyPath('cornerRadius')
      animation.duration = splashAnimationDuration
      animation.timingFunction = CAMediaTimingFunction.functionWithName(KCAMediaTimingFunctionEaseOut)
      splash_circle.layer.addAnimation animation, forKey:nil
      splash_circle.layer.cornerRadius = 35 / 2
      UIView.animateWithDuration splashAnimationDuration, delay:0, options:0,
        animations: -> {splash_circle.frame = [[7,50],[35,35]] }, completion: -> _ {}
      UIView.animateWithDuration splashAnimationDuration, delay:splashAnimationDuration, options:UIViewAnimationOptionCurveEaseInOut,
        animations: -> { splash_circle.alpha = 0 }, completion: -> _ {}
    end
  end

  def timeSelectionChanged(timeSelection)
    familySittersController.timeSelection = timeSelection
  end

  def navigationController(navigationController, willShowViewController:targetController, animated:flag)
    mode = targetController == familySittersController ? :interactive : :summary
    timeSelectionController.setMode mode, animated:true
  end

  def presentSuggestedSitters
    TestFlight.passCheckpoint 'Suggested sitters'
    recommendedSittersController.title = 'Sitters'
    navigationController.pushViewController recommendedSittersController, animated:true
  end

  def presentDetailsForSitter(sitter)
    TestFlight.passCheckpoint "Sitter details: #{sitter.name}"
    sitterDetailsController.title = sitter.firstName
    sitterDetailsController.sitter = sitter
    sitterDetailsController.action = case
      when Family.instance.canAddSitter(sitter) then :add
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
  attr_reader :familySittersController

  def sitterDetailsController
    @sitterDetailsController ||= SitterDetailsController.alloc.init.tap do |controller| controller.delegate = self end
  end

  def recommendedSittersController
    @recommendedSittersController ||= RecommendedSittersController.alloc.init.tap do |controller| controller.delegate = self end
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
      Family.instance.addSitter sitter
      delegate.actionDelegateDidComplete self
      UIAlertView.alloc.initWithTitle('Sitter Confirmed',
        message:"%s has accepted your request. We’ve added her to your Seven Sitters." % sitter.firstName,
        delegate:nil,
        cancelButtonTitle:'OK',
        otherButtonTitles:nil).show
    end
  end
end
