class Server
  private

  attr_reader :firebaseEnvironment
  attr_reader :requestsFB
  attr_reader :messagesFB
  attr_reader :userMessagesFB

  public

  def self.instance
    Dispatch.once { @instance ||= new }
    @instance
  end

  def initialize
    @firebaseEnvironment = UIApplication.sharedApplication.delegate.firebaseEnvironment
    @requestsFB = firebaseEnvironment['request']
  end

  def sendRequest(requestKey, withParameters:parameters)
    unless NSJSONSerialization.isValidJSONObject(parameters)
      parameters = parameters.clone
      for key, value in parameters
        parameters[key] = value.ISO8601StringFromDate if value.instance_of?(NSDate)
        parameters[key] = value.ISO8601StringFromDate if value.instance_of?(Time)
      end
    end
    NSLog "Request %@ with %@", requestKey, parameters
    if shouldEmulateServer
      EmulatedServer.instance.handleRequest requestKey, withParameters:parameters
    else
      requestString = requestKey.gsub(/_(.)/) { $1.upcase } # snake_case -> camelCase
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

  def subscribeToMessagesForAccount(account)
    unsubscribeFromUserMessages
    @userMessagesFB = firebaseEnvironment['message'][account.accountKey]
    NSLog "Subscribing to %@", userMessagesFB
    userMessagesFB.on(:child_added) do |snapshot|
      message = snapshot.value
      # messageText = MessageTemplate.messageTemplateToString(message['messageText'], withParameters:parameters)
      # App.alert message['messageTitle'], message:messageText
      userMessagesFB[snapshot.name].clear!
      messageType = message['messageType']
      parameters = message['parameters']
      NSLog "Relaying firebase #{messageType} with #{parameters}"
      NSNotificationCenter.defaultCenter.postNotificationName messageType, object:self, userInfo:parameters
    end
  end

  def registerDeviceToken(token, forUser:user)
    token = token.description.gsub(/[< >]/, '')
    sendRequest :register_device_token, withParameters:{token:token}
  end

  def unsubscribeFromUserMessages
    if userMessagesFB
      NSLog "Unsubscribing from %@", userMessagesFB
      userMessagesFB.off
      @userMessagesFB = nil
    end
  end

  def shouldEmulateServer
    return NSUserDefaults.standardUserDefaults['emulateServer'] || Account.instance.user.nil?
  end
end

# An embedded emulation of the server, for demo mode and serverless development and testing.
# Sends messages back to the application using local modifications instead of Firebase.
class EmulatedServer
  EmulatedServerMessageName = 'emulatedServerMessage'

  def self.instance
    Dispatch.once { @instance ||= new }
    @instance
  end

  def initialize
    App.notification_center.observe(EmulatedServerMessageName) do |notification|
      messageType = notification.userInfo['messageType']
      NSLog "Relaying notification #{messageType} with #{notification.userInfo['parameters']}"
      NSNotificationCenter.defaultCenter.postNotificationName messageType, object:self, userInfo:notification.userInfo['parameters']
    end
  end

  def handleRequest(requestKey, withParameters:parameters)
    parameters = MotionMap::Map.new(parameters)
    case requestKey

    when :add_sitter
      sendMessageToClient :sitterAcceptedConnection,
        messageTemplate:"{{sitter.firstName}} has accepted your request. We’ve added her to your Seven Sitters.",
        withDelay:simulateSitterConfirmationDelay,
        withParameters:{sitterId:parameters[:sitterId]}

      App.run_after(simulateSitterConfirmationDelay) do
        family = Family.instance
        sitter = Sitter.findSitterById(parameters[:sitterId])
        family.addSitter sitter if sitter
      end

    when :reserve_sitter
      sendMessageToClient :sitterConfirmedReservation,
        messageTemplate:"{{sitter.firstName}} has confirmed your request.",
        withDelay:simulateSitterConfirmationDelay,
        withParameters:{sitterId:parameters[:sitterId], startTime:parameters[:startTime], endTime:parameters[:endTime]}

    when :set_sitter_count
      Family.instance.setSitterCount parameters[:count]

    else
      NSLog "Server emulator: unknown request type %@", requestKey

    end
  end

  private

  def messagesFB
    firebaseEnvironment = UIApplication.sharedApplication.delegate.firebaseEnvironment
    # don't cache, since changes when account changes
    return firebaseEnvironment['message'][Account.instance.accountKey]
  end

  def simulateSitterConfirmationDelay
    NSUserDefaults.standardUserDefaults['simulateSitterConfirmationDelay'] ? 10 : 0.1
  end

  # Don't use this, since it introduces a network dependency on demo mode
  # TODO use this when the user is signed in, for greater fidelity and since this requires the network anyway
  def sendMessageToClientUsingFirebase(messageType, messageTemplate:messageTemplate, withDelay:delay, withParameters:parameters)
    NSLog "Schedule #{messageType} for t+#{delay}s with parameters=#{parameters}"
    messages = {
      messageType: messageType,
      messageTitle: messageTemplate[:messageTitle],
      messageText: MessageTemplate.messageTemplateToString(messageTemplate, withParameters:parameters),
      parameters: parameters
    }
    App.run_after(delay) { messagesFB << message }
  end

  def sendMessageToClientUsingLocalNotifications(messageType, messageTemplate:messageTemplate, withDelay:delay, withParameters:parameters)
    NSLog "Schedule #{messageType} for t+#{delay}s with parameters=#{parameters}"

    messageText = MessageTemplate.messageTemplateToString(messageTemplate, withParameters:parameters)
    # round-trip through JSON, to increase emulation fidelity to server
    parameters = BW::JSON.parse(BW::JSON.generate(parameters))

    notification = UILocalNotification.alloc.init
    notification.fireDate = NSDate.dateWithTimeIntervalSinceNow(delay)
    notification.alertBody = messageText
    notification.applicationIconBadgeNumber = 1
    notification.userInfo = {
      notificationName: EmulatedServerMessageName,
      messageType: messageType,
      messageText: messageText,
      parameters: parameters
    }
    UIApplication.sharedApplication.scheduleLocalNotification notification
  end

  # alias_method 'sendMessageToClient:messageTemplate:withDelay:withParameters:', 'sendMessageToClientUsingFirebase:messageTemplate:withDelay:withParameters:'
  alias_method 'sendMessageToClient:messageTemplate:withDelay:withParameters:', 'sendMessageToClientUsingLocalNotifications:messageTemplate:withDelay:withParameters:'
end

module MessageTemplate
  def self.messageTemplateToString(template, withParameters:parameters)
    # keyword keys into strings
    # parameters = BW::JSON.parse(BW::JSON.generate(parameters)) if parameters
    parameters = MotionMap::Map.new(parameters)
    # parameters = Map.new(parameters)
    return template.gsub('{{sitter.firstName}}') { Sitter.findSitterById(parameters[:sitterId]).firstName }
  end
end
