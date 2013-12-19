class Account
  include BW::KVO
  FacebookPermissions = ['email']
  # FacebookPermissions = %w[email read_friendlists user_hometown user_location user_relationships]

  attr_accessor :user

  # The device APNS token. This is saved in the account so that a future login can send it to the server.
  attr_reader :deviceToken

  # The credit card, or nil.
  #
  # Properties:
  #  :last4 - The last four digits of the card number
  #  :cardType - String
  #  :expirationMonth - Number
  #  :expirationYear - Number
  attr_accessor :cardInfo

  def self.instance
    Dispatch.once { @instance ||= new }
    @instance
  end

  def initialize
    firebaseRoot['.info/authenticated'].on(:value) do |snapshot|
      # value is 0 on initialization, and then true or false
      Logger.info "Auth status = #{snapshot.value}"
      if snapshot.value == false
        self.user = nil
        didLogout
      end
    end
  end

  def initializeLoginStatus
    Logger.info "auth.check"
    auth.check do |error, user|
      Logger.info "auth.check error=%@", error if error
      Logger.info "auth.check user=%@", user if user
      self.user = user
    end
  end

  def user=(user)
    self.willChangeValueForKey :user
    injectUserInstanceMethods user if user
    @user = user
    self.didChangeValueForKey :user
    updateUserDataSubscription
  end

  def loginWithRole(role)
    return if user
    Logger.checkpoint 'Login'
    App.notification_center.postNotification ApplicationWillAttemptLoginNotification
    # avoid auth.check because it never returns when the network is offline.
    facebookAppId = App.delegate.getAPIToken('FacebookAppId')
    auth.login_to_facebook(app_id:facebookAppId, permissions:FacebookPermissions) do |error, user|
      App.delegate.userRole = role if user
      authDidReturnUser user, error:error
    end
  end

  def logout
    Logger.checkpoint 'Logout'
    auth.logout
    # the .info/authenticated observation clears self.user if logout succeeded
  end

  def accountKey
    providerNames = [nil, 'password', 'facebook', 'twitter']
    userProvider = providerNames[user.provider]
    "#{userProvider}-#{user.userId}"
  end

  def deviceToken=(token)
    @deviceToken = token
    Server.instance.registerDeviceToken token, forUser:user if user and token
  end

  private

  def injectUserInstanceMethods(user)
    class << user
      def displayName
        self.thirdPartyUserData['displayName']
      end

      def email
        super || self.thirdPartyUserData['email']
      end

      def locationName
        location = self.thirdPartyUserData['location']
        location ? location['name'] : nil
      end
    end
  end

  def auth
    @auth ||= FirebaseSimpleLogin.new(firebaseRoot)
  end

  def firebaseRoot
    return App.delegate.firebaseRoot
  end

  def firebaseEnvironment
    return App.delegate.firebaseEnvironment
  end

  def family
    Family.instance
  end

  def authDidReturnUser(user, error:error)
    Logger.info "login: user=%@", user if user
    Logger.info "login: error=%@", error if error
    self.user = user
    if error
      UIAlertView.alloc.initWithTitle(error.localizedDescription,
        message:error.localizedRecoverySuggestion,
        delegate:nil,
        cancelButtonTitle:'OK',
        otherButtonTitles:error.localizedRecoveryOptions).show
    end
    Server.instance.registerUser user, withRole:App.delegate.userRole if user
    App.notification_center.postNotificationName ApplicationDidAttemptLoginNotification.name,
      object:self,
      userInfo:{error:error, user:user}
  end

  def didLogout
    App.delegate.userRole = nil
  end

  # TODO move some of this into storage manager
  # TODO cache
  def updateUserDataSubscription
    if @currentAccountFB
      Logger.info "Unsubscribing from %@", @currentAccountFB
      @currentAccountFB.off
      @currentAccountFB = nil
    end
    Server.instance.unsubscribeFromAccountMessages
    return unless user

    Server.instance.subscribeToMessagesForAccount self
    Server.instance.registerDeviceToken deviceToken, forUser:user if deviceToken

    accountPath = "user/auth/#{accountKey}"
    @currentAccountFB = firebaseEnvironment[accountPath]
    Storage.instance.onCachedFirebaseValue(accountPath, {cacheVersion:2}) do |accountData|
      @accountData = accountData
      if accountData
        self.cardInfo = accountData['cardInfo'] ? MotionMap::Map.new(accountData['cardInfo']) : nil
        family.updateFrom accountData if accountData
      end
    end
  end
end
