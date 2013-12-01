class Server
  private

  API_VERSION = 1

  attr_reader :firebaseEnvironment
  attr_reader :requestsFB
  attr_reader :userMessagesFB

  public

  def self.instance
    Dispatch.once { @instance ||= new }
    @instance
  end

  def initialize
    @firebaseEnvironment = App.delegate.firebaseEnvironment
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
    Logger.info "Request %@ with %@", requestKey, parameters
    if shouldEmulateServer
      EmulatedServer.instance.handleRequest requestKey, withParameters:parameters
    else
      request = {
        requestType: requestKey.gsub(/_(.)/) { $1.upcase }, # snake_case -> camelCase
        apiVersion:  API_VERSION,
        deviceUuid:  UIDevice.currentDevice.identifierForVendor.UUIDString,
        ipAddress:   NetworkUtils.getIPAddress(true),
        parameters:  parameters,
        timestamp:   NSDate.date.ISO8601StringFromDate,
        userAuthId:  Account.instance.accountKey
      }
      requestsFB << request
      # ping the server to wake it
      BW::HTTP.get 'http://api.7sitters.com/ping' unless Device.simulator?
    end
  end

  def registerPaymentToken(token, cardInfo)
    sendRequest :register_payment_token, withParameters:{token:token, cardInfo:cardInfo}
  end

  def registerUser(user)
    sendRequest :register_user, withParameters:{displayName:user.displayName, email:user.email}
  end

  def removePaymentCard(cardInfo)
    sendRequest :remove_payment_card, withParameters:{cardInfo:cardInfo}
  end

  # For demo and testing
  def setSitterCount(count)
    # The early return presents a race condition for setting this twice in a high-latency
    # environment, but this method is only used for test and demo purposes anyway.
    return if count == Family.instance.sitters.length
    sendRequest :set_sitter_count, withParameters:{count:count}
  end

  def subscribeToMessagesForAccount(account)
    unsubscribeFromAccountMessages
    @userMessagesFB = firebaseEnvironment['message']['user']['auth'][account.accountKey]
    Logger.info "Subscribing to %@", userMessagesFB
    userMessagesFB.on(:child_added) do |snapshot|
      message = snapshot.value
      messageApiVersion = message['apiVersion']
      if messageApiVersion == API_VERSION
        # Clear it first, so that it will only crash the client once
        userMessagesFB[snapshot.name].clear!
        processMessage(message)
      else
        # Leave it place in case there's other clients at the old version
        Logger.info "Ignoring with api version #{messageApiVersion}: %@", message
      end
    end
  end

  def registerDeviceToken(token, forUser:user)
    token = token.description.gsub(/[< >]/, '')
    sendRequest :register_device_token, withParameters:{token:token}
  end

  def unsubscribeFromAccountMessages
    if userMessagesFB
      Logger.info "Unsubscribing from %@", userMessagesFB
      userMessagesFB.off
      @userMessagesFB = nil
    end
  end

  private

  def processMessage(message)
    messageType = message['messageType']
    parameters = message['parameters']
    Logger.info "Relaying firebase #{messageType} with #{parameters}"
    App.notification_center.postNotificationName messageType, object:self, userInfo:parameters
  end

  def shouldEmulateServer
    return true if Account.instance.user.nil?
    return App.delegate.recordUserSettingDependency('emulateServer')
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
      Logger.info "Relaying notification #{messageType} with #{notification.userInfo['parameters']}"
      App.notification_center.postNotificationName messageType, object:self, userInfo:notification.userInfo['parameters']
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
    end
  end

  private

  def messagesFB
    firebaseEnvironment = App.delegate.firebaseEnvironment
    # don't cache, since changes when account changes
    return firebaseEnvironment['message']['user']['auth'][Account.instance.accountKey]
  end

  def simulateSitterConfirmationDelay
    NSUserDefaults.standardUserDefaults['simulateSitterConfirmationDelay'] ? 10 : 0.1
  end

  # Don't use this, since it introduces a network dependency on demo mode
  # TODO use this when the user is signed in, for greater fidelity and since this requires the network anyway
  def sendMessageToClientUsingFirebase(messageType, messageTemplate:messageTemplate, withDelay:delay, withParameters:parameters)
    Logger.info "Schedule #{messageType} for t+#{delay}s with parameters=#{parameters}"
    messages = {
      messageType: messageType,
      messageTitle: messageTemplate[:messageTitle],
      messageText: MessageTemplate.messageTemplateToString(messageTemplate, withParameters:parameters),
      parameters: parameters
    }
    App.run_after(delay) { messagesFB << message }
  end

  def sendMessageToClientUsingLocalNotifications(messageType, messageTemplate:messageTemplate, withDelay:delay, withParameters:parameters)
    Logger.info "Schedule #{messageType} for t+#{delay}s with parameters=#{parameters}"

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
    App.shared.scheduleLocalNotification notification
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
