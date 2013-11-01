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
    shouldEmulateServer = NSUserDefaults.standardUserDefaults['emulateServer'] || Account.instance.user.nil?

    if shouldEmulateServer
      case action
      when :add_sitter
        notification = UILocalNotification.alloc.init
        notification.fireDate = NSDate.dateWithTimeIntervalSinceNow(10)
        notification.alertBody = "%s has accepted your request. We’ve added her to your Seven Sitters." % sitter.firstName
        notification.applicationIconBadgeNumber = 1
        notification.userInfo = {notificationName:'addSitter', sitter_id:sitter.id, message:notification.alertBody}
        UIApplication.sharedApplication.scheduleLocalNotification notification
      end
    else
      case action
      when :add_sitter
        sendMessageToServer 'addSitter', sitterId: sitter.id, familyId: Family.instance.id
      end
    end

    messageText = case action
      when :add_sitter then "We’ve just sent a request to add %s to your Seven Sitters. We’ll let you know when she confirms."
      when :reserve_sitter then "%s will babysit for you at the specified time."
      when :request_sitter then "We’ve just sent a request to %s. We’ll let you know whether she’s available."
    end
    App.alert 'Request Sent', message:messageText % sitter.firstName
  end

  def sendMessageToServer(requestType, parameters)
    firebase = UIApplication.sharedApplication.delegate.firebase
    message = ({requestType:requestType, userId:Account.instance.accountKey, parameters:parameters})
    firebase['request'] << message
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
