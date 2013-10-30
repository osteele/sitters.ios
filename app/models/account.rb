class Account
  include BW::KVO
  attr_accessor :user

  def self.instance
    Dispatch.once { @instance ||= new }
    @instance
  end

  def initialize
    firebase['.info/authenticated'].on(:value) do |snapshot|
      NSLog "Auth status: update to #{snapshot.value}"
      self.user = nil if not snapshot.value
    end
    observe(family, :sitters) do
      familySittersDidChange
    end
  end

  def initialize_login_status
    NSLog "Auth status: checking"
    auth.check do |error, user|
      NSLog "Auth status: #{!!user}"
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
    NSNotificationCenter.defaultCenter.postNotification ApplicationWillAttemptLoginNotification
    auth.check do |error, user|
      if error or user
        authDidReturnUser user, error:error
        NSNotificationCenter.defaultCenter.postNotification ApplicationDidAttemptLoginNotification
      else
        permissions = ['email', 'read_friendlists', 'user_hometown', 'user_location', 'user_relationships']
        auth.login_to_facebook(app_id: FacebookAppId, permissions: ['email']) do |error, user|
          authDidReturnUser user, error:error
          NSNotificationCenter.defaultCenter.postNotification ApplicationDidAttemptLoginNotification
        end
      end
    end
  end

  def logout
    auth.logout
    # the .info/authenticated observation clears self.user
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
    self.user = user
    if error
      UIAlertView.alloc.initWithTitle(error.localizedDescription,
        message:error.localizedRecoverySuggestion,
        delegate:nil,
        cancelButtonTitle:'OK',
        otherButtonTitles:error.localizedRecoveryOptions).show
    end
  end

  # TODO move some of this into storage manager
  # TODO cache
  def updateUserDataSubscription
    @userDataFB.off if @userDataFB
    @familyDataFB.off if @familyDataFB
    @userDataFB = nil
    @familyDataFB = nil
    @familyData = nil
    return unless user

    accountsFB = firebase['account']
    familiesFB = firebase['family']
    providerNames = [nil, 'password', 'facebook', 'twitter']

    userProvider = providerNames[user.provider]
    accountKey = "#{userProvider}/#{user.userId}"
    @userFB = accountsFB[accountKey]
    # @userFB.on(:value) do |snapshot|
    DataCache.instance.onCachedFirebaseValue(firebase, "account/#{accountKey}") do |data|
      if data
        family_id = data['family_id']
        @familyDataFB = familiesFB[family_id]
        # @familyDataFB.on(:value) do |snapshot|
        DataCache.instance.onCachedFirebaseValue(firebase, "family/#{family_id}") do |data|
          @familyData = data
          family.updateFrom data if data
        end
      else
        familyFB = familiesFB << {parents: {userProvider => user.userId}, sitter_ids: family.sitters.map(&:id)}
        accountsFB[accountKey] = {displayName: user.displayName, email: user.thirdPartyUserData['email'], family_id: familyFB.name}
      end
    end
  end

  def familySittersDidChange
    sitter_ids = family.sitters.map(&:id)
    return unless @familyData
    @familyDataFB['sitter_ids'] = sitter_ids unless @familyData['sitter_ids'] == sitter_ids
  end
end
