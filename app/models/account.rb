class Account
  include BW::KVO
  attr_accessor :user

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
    @userDataFB.off if @userDataFB
    @userDataFB = nil
    @familyDataFB.off if @familyDataFB
    @familyDataFB = nil
    @familyData = nil
    Server.instance.unsubscribeFromMessages
    return unless user

    accountsFB = firebase['account']
    familiesFB = firebase['family']
    providerNames = [nil, 'password', 'facebook', 'twitter']
    userProvider = providerNames[user.provider]
    @userFB = accountsFB[accountKey]
    # @userFB.on(:value) do |snapshot|
    Storage.instance.onCachedFirebaseValue("account/#{accountKey}") do |data|
      if data
        family_id = data['family_id']
        @familyDataFB = familiesFB[family_id]
        # @familyDataFB.on(:value) do |snapshot|
        Storage.instance.onCachedFirebaseValue("family/#{family_id}") do |data|
          @familyData = data
          family.id = family_id
          family.updateFrom data if data
        end
      else
        familyFB = familiesFB << {parents: {userProvider => user.userId}, sitter_ids: family.sitters.map(&:id)}
        accountsFB[accountKey] = {displayName: user.displayName, email: user.thirdPartyUserData['email'], family_id: familyFB.name}
      end
    end

    Server.instance.subscribeToMessagesFor accountKey
  end

  def familySittersDidChange
    sitter_ids = family.sitters.map(&:id)
    return unless @familyData
    @familyDataFB['sitter_ids'] = sitter_ids unless @familyData['sitter_ids'] == sitter_ids
  end
end
