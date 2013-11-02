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
    sitterDetailsController.sitter_action = case
      when Family.instance.canAddSitter(sitter) then :add_sitter
      when sitter.availableAt(timeSelectionController.timeSelection) then :reserve_sitter
      else :request_sitter
      end
    navigationController.pushViewController sitterDetailsController, animated:true
  end

  def performSitterAction(action, sitter:sitter)
    parameters = {sitterId: sitter.id, familyId: Family.instance.id}
    Server.instance.sendRequest action, withParameters:parameters

    messageTemplate = {
      add_sitter: "We’ve just sent a request to add {{sitter.firstName}} to your Seven Sitters. We’ll let you know when she confirms.",
      reserve_sitter: "We’ve reserved {{sitter.firstName}} to babysit for you at the specified time. We’ll let you know when she confirms.",
      request_sitter: "We’ve just sent a request to {{sitter.firstName}}. We’ll let you know whether she’s available.",
    }[action]
    App.alert 'Request Sent', message:MessageTemplate.messageTemplateToString(messageTemplate, withParameters:parameters) if messageTemplate
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
