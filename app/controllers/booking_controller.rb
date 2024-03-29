class BookingController < UIViewController
  include BW::KVO
  stylesheet :booking

  def initWithNibName(name, bundle:bundle)
    super
    self.tabBarItem = UITabBarItem.alloc.initWithTitle('Sitters', image:UIImage.imageNamed('tabs/sitters'), tag:1)
    self
  end

  def viewDidLoad
    super
    view.stylename = :sitters
    view.backgroundColor = UIColor.whiteColor
    familySittersController.timeSelection = timeSelectionController.timeSelection

    App.notification_center.observe('sitterAcceptedConnection') do |notification|
      sitter = Sitter.findSitterById(notification.userInfo['sitterId'])
      if sitter
        App.alert 'Sitter Confirmed', message:"#{sitter.firstName} has accepted your request. We’ve added her to your Seven Sitters."
      end
    end

    App.notification_center.observe('sitterConfirmedReservation') do |notification|
      sitter = Sitter.findSitterById(notification.userInfo['sitterId'])
      if sitter
        startTime = NSDate.dateFromISO8601String(notification.userInfo['startTime'])
        endTime = NSDate.dateFromISO8601String(notification.userInfo['endTime'])
        hourFormatter = NSDateFormatter.alloc.init.setTimeStyle(NSDateFormatterShortStyle)
        startTimeString = hourFormatter.stringFromDate(startTime)
        endTimeString = hourFormatter.stringFromDate(endTime)
        dayString = startTime.relativeDayFromDate
        message = "#{sitter.firstName} has confirmed your reservation from #{startTimeString} to #{endTimeString} #{dayString}"
        App.alert 'Sitter Confirmed', message:message
      end
    end
  end

  layout do
    @familySittersController = SittersController.alloc.init.tap do |c| c.delegate = self end
    @navigationController = UINavigationController.alloc.initWithRootViewController(familySittersController).tap do |c| c.delegate = self end
    @timeSelectionController = TimeSelectionController.alloc.init.tap do |c| c.delegate = self end

    subview @navigationController.view
    # subview UIView, :status_bar_background
    subview @timeSelectionController.view
  end

  def timeSelectionDidChangeTo(timeSelection)
    familySittersController.timeSelection = timeSelection
  end

  def navigationController(navigationController, willShowViewController:targetController, animated:flag)
    mode = targetController == familySittersController ? :interactive : :summary
    timeSelectionController.setMode mode, animated:true
  end

  def inviteSitter
    Logger.checkpoint 'Invite sitter'
    peoplePicker = ABPeoplePickerNavigationController.alloc.init
    peoplePicker.peoplePickerDelegate = self
    self.presentViewController peoplePicker, animated:true, completion:nil
  end

  def peoplePickerNavigationController(controller, shouldContinueAfterSelectingPerson:person)
    return true
  end

  def peoplePickerNavigationController(controller, shouldContinueAfterSelectingPerson:person, property:property, identifier:id)
    index = id
    # index = ABMultiValueGetIndexForIdentifier(property, id) unless id == KABMultiValueInvalidIdentifier
    case property
    when KABPersonEmailProperty
    when KABPersonFirstNameProperty
      name = 'email'
    when KABPersonPhoneProperty
      name = 'phone'
    else
      return false
    end
    self.dismissViewControllerAnimated true, completion:nil
    values = ABRecordCopyValue(person, property)
    array = ABMultiValueCopyArrayOfAllValues(values)
    value = array[index]
    firstName = ABRecordCopyValue(person, KABPersonFirstNameProperty)
    message = "Your invitation will be sent to %s at %s." % [firstName, value]
    App.alert "Invitation Underway", message:message
    return false
  end

  def peoplePickerNavigationControllerDidCancel(controller)
    self.dismissViewControllerAnimated true, completion:nil
  end

  def presentSuggestedSitters
    Logger.checkpoint 'Suggested sitters'
    recommendedSittersController.title = 'Sitters'
    navigationController.pushViewController recommendedSittersController, animated:true
  end

  def presentDetailsForSitter(sitter)
    Logger.checkpoint 'Sitter details'
    sitterDetailsController.title = sitter.firstName
    sitterDetailsController.sitter = sitter
    sitterDetailsController.sitter_action = case
      when Family.instance.canAddSitter(sitter) then :add_sitter
      when sitter.availableAt(timeSelectionController.timeSelection) then :reserve_sitter
      else :request_sitter
      end
    navigationController.pushViewController sitterDetailsController, animated:true
  end

  def performSitterAction(requestType, sitter:sitter)
    Logger.checkpoint 'Request sitter'
    parameters = {sitterId:sitter.id}
    if [:request_sitter, :reserve_sitter].include?(requestType)
      requestType = :reserve_sitter
      parameters = parameters.merge(startTime:timeSelection.startTime, endTime:timeSelection.endTime)
    end
    Server.instance.sendRequest requestType, withParameters:parameters

    messageTemplate = {
      add_sitter: "We’ve just sent a request to add {{sitter.firstName}} to your Seven Sitters. We’ll let you know when she confirms.",
      # reserve_sitter: "We’ve reserved {{sitter.firstName}} to babysit for you at the specified time. We’ll let you know when she confirms.",
      reserve_sitter: "We’ve just sent a request to {{sitter.firstName}}. We’ll let you know whether she’s available.",
    }[requestType]
    App.alert 'Request Sent', message:MessageTemplate.messageTemplateToString(messageTemplate, withParameters:parameters) if messageTemplate
  end

  private

  def navigationController; @navigationController; end
  attr_reader :timeSelectionController
  attr_reader :familySittersController

  def timeSelection
    timeSelectionController.timeSelection
  end

  def sitterDetailsController
    @sitterDetailsController ||= SitterDetailsController.alloc.init.tap do |controller| controller.delegate = self end
  end

  def recommendedSittersController
    @recommendedSittersController ||= RecommendedSittersController.alloc.init.tap do |controller| controller.delegate = self end
  end
end
