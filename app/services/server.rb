class Server
  def self.instance
    Dispatch.once { @instance ||= new }
    @instance
  end

  def initialize
    @firebase = UIApplication.sharedApplication.delegate.firebase
    @requestsFB = firebase['request']
  end

  def sendRequest(requestKey, withParameters:parameters)
    if shouldEmulateServer
      EmulatedServer.instance.handleRequest requestKey, withParameters:parameters
    else
      requestString = requestKey.gsub(/_(.)/) {$1.upcase }
      request = {requestType:requestString, accountKey:Account.instance.accountKey, parameters:parameters}
      requestsFB << request
    end
  end

  def setSitterCount(count)
    sendRequest :set_sitter_count, withParameters: {count:count}
  end

  def registerUser(user)
    sendRequest :register_user, withParameters: {displayName:user.displayName, email:user.email}
  end

  def subscribeToMessagesFor(accountKey)
    @userMessagesFB = firebase['message'][accountKey]
    userMessagesFB.on(:child_added) do |snapshot|
      message = snapshot.value
      messageText = MessageTemplate.messageTemplateToString(message['messageText'], withParameters:message['parameters'])
      App.alert message['messageTitle'], message:messageText
      userMessagesFB[snapshot.name].clear!
    end
  end

  def registerDeviceToken(token, forUser:user)
    token = token.description.gsub(/[< >]/, '')
    sendRequest :register_device_token, withParameters:{token:token}
  end

  def unsubscribeFromMessages
    userMessagesFB.off if userMessagesFB
    @userMessagesFB = nil
  end

  private

  attr_reader :firebase
  attr_reader :requestsFB
  attr_reader :messagesFB
  attr_reader :userMessagesFB

  def shouldEmulateServer
    return NSUserDefaults.standardUserDefaults['emulateServer'] || Account.instance.user.nil?
  end
end

class EmulatedServer
  def self.instance
    Dispatch.once { @instance ||= new }
    @instance
  end

  def handleRequest(requestKey, withParameters:parameters)
    # keyword keys into strings
    parameters = BW::JSON.parse(BW::JSON.generate(parameters))
    case requestKey
    when :add_sitter
      sendMessageToClient("{{sitter.firstName}} has accepted your request. We’ve added her to your Seven Sitters.",
        withDelay:10,
        withParameters:{notificationName:'addSitter', sitterId:parameters['sitterId']})
    when :set_sitter_count
      Family.instance.setSitterCount parameters['count']
    end
  end

  private

  def sendMessageToClient(messageTemplate, withDelay:delay, withParameters:parameters)
    NSLog "Schedule message for t+#{delay}s"
    messageText = MessageTemplate.messageTemplateToString(messageTemplate, withParameters:parameters)
    parameters = parameters.merge message: messageText
    notification = UILocalNotification.alloc.init
    notification.fireDate = NSDate.dateWithTimeIntervalSinceNow(delay)
    notification.alertBody = messageText
    notification.applicationIconBadgeNumber = 1
    notification.userInfo = parameters
    UIApplication.sharedApplication.scheduleLocalNotification notification
  end
end

module MessageTemplate
  def self.messageTemplateToString(template, withParameters:parameters)
    # keyword keys into strings
    parameters = BW::JSON.parse(BW::JSON.generate(parameters)) if parameters
    return template.gsub('{{sitter.firstName}}') { Sitter.findSitterById(parameters['sitterId']).firstName }
  end
end
