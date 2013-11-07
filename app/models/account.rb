class Account
  include BW::KVO
  attr_accessor :user
  attr_reader :deviceToken

  def self.instance
    Dispatch.once { @instance ||= new }
    @instance
  end

  def initialize
    firebase['.info/authenticated'].on(:value) do |snapshot|
      # value is 0 on initialization, and then true or false
      NSLog "Auth status = #{snapshot.value}"
      self.user = nil if snapshot.value == false
    end
    observe(family, :sitters) do
      familySittersDidChange
    end
  end

  def initialize_login_status
    NSLog "auth.check"
    auth.check do |error, user|
      NSLog "auth.check user=#{user} error=#{error}"
      self.user = user
    end
  end

  def user=(user)
    self.willChangeValueForKey :user
    add_user_methods user if user
    @user = user
    self.didChangeValueForKey :user
    updateUserDataSubscription
  end

  def login
    return if user
    NSNotificationCenter.defaultCenter.postNotification ApplicationWillAttemptLoginNotification

    NSLog "login: login_to_facebook"
    permissions = ['email', 'read_friendlists', 'user_hometown', 'user_location', 'user_relationships']
    auth.login_to_facebook(app_id: FacebookAppId, permissions: ['email']) do |error, user|
      authDidReturnUser user, error:error
    end

    # auth.check, below, never returns when the network is offline.

    # NSLog "login: auth.check"
    # auth.check do |error, user|
    #   NSLog "login: auth.check callback"
    #   if error or user
    #     authDidReturnUser user, error:error
    #   else
    #     NSLog "login: login_to_facebook"
    #     permissions = ['email', 'read_friendlists', 'user_hometown', 'user_location', 'user_relationships']
    #     auth.login_to_facebook(app_id: FacebookAppId, permissions: ['email']) do |error, user|
    #       authDidReturnUser user, error:error
    #     end
    #   end
    # end
  end

  def logout
    NSLog 'login'
    auth.logout
    # the .info/authenticated observation clears self.user
  end

  def accountKey
    providerNames = [nil, 'password', 'facebook', 'twitter']
    userProvider = providerNames[user.provider]
    "#{userProvider}/#{user.userId}"
  end

  def deviceToken=(token)
    @deviceToken = token
    Server.instance.registerDeviceToken token, forUser:user if user and token
  end

  private

  FacebookAppId = '245805915569604'

  def add_user_methods(user)
    class << user
      def displayName
        self.thirdPartyUserData['displayName']
      end

      def locationName
        location = self.thirdPartyUserData['location']
        location ? location['name'] : nil
      end
    end
  end

  def auth
    @auth ||= FirebaseSimpleLogin.new(firebase)
  end

  def firebase
    app = UIApplication.sharedApplication.delegate
    return app.firebase
  end

  def family
    Family.instance
  end

  def authDidReturnUser(user, error:error)
    NSLog "login: error=#{error} user=#{user}"
    self.user = user
    if error
      UIAlertView.alloc.initWithTitle(error.localizedDescription,
        message:error.localizedRecoverySuggestion,
        delegate:nil,
        cancelButtonTitle:'OK',
        otherButtonTitles:error.localizedRecoveryOptions).show
    end
    NSNotificationCenter.defaultCenter.postNotification ApplicationDidAttemptLoginNotification
  end

  # TODO move some of this into storage manager
  # TODO cache
  def updateUserDataSubscription
    @currentAccountFB.off if @currentAccountFB
    @currentAccountFB = nil
    @currentFamilyFB.off if @currentFamilyFB
    @currentFamilyFB = nil
    @familyData = nil
    Server.instance.unsubscribeFromMessages
    return unless user

    Server.instance.registerUser user
    Server.instance.subscribeToMessagesFor accountKey
    Server.instance.registerDeviceToken deviceToken, forUser:user if deviceToken

    accountPath = "account/#{accountKey}"
    @currentAccountFB = firebase[accountPath]
    Storage.instance.onCachedFirebaseValue(accountPath) do |accountData|
      if accountData
        family_id = accountData['family_id']
        familyPath = "family/#{family_id}"
        @currentFamilyFB = firebase[familyPath]
        Storage.instance.onCachedFirebaseValue(familyPath) do |familyData|
          @familyData = familyData
          family.id = family_id
          family.updateFrom familyData if familyData
        end
      end
    end
  end

  def familySittersDidChange
    sitter_ids = family.sitters.map(&:id)
    if @currentFamilyDataFB and @currentFamilyDataFB['sitter_ids'] != sitter_ids
      @currentFamilyDataFB['sitter_ids'] = sitter_ids
    end
  end
end
