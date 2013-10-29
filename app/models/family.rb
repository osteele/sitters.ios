class Family
  include BW::KVO
  InitialSitterCount = 6
  MaxSitterCount = 7

  attr_accessor :sitters
  attr_accessor :suggested_sitters

  def self.instance
    Dispatch.once { @instance ||= new }
    @instance
  end

  def initialize
    setupUserData
    observe(Account.instance, :user) do setupUserData end
  end

  # TODO move some of this into Account
  # TODO refactor
  # TODO cache
  # TODO initialize from stored value
  # TODO update when sitter list changes
  def setupUserData
    app = UIApplication.sharedApplication.delegate
    firebase = app.firebase
    accountsFB = firebase['account']
    familiesFB = firebase['family']
    providerNames = [nil, 'password', 'facebook', 'twitter']
    @userFB.off if @userFB
    @userFB = nil
    user = Account.instance.user
    if user
      userProvider = providerNames[user.provider]
      accountKey = "#{userProvider}/#{user.userId}"
      @userFB = firebase['account'][accountKey]
      @userFB.once(:value) do |snapshot|
        unless snapshot.value
          familyFB = familiesFB << {parents: {userProvider => user.userId}, sitter_ids: self.sitters.map(&:id)}
          accountsFB[accountKey] = {displayName: user.displayName, email: user.thirdPartyUserData['email'], family_id: familyFB.name}
        end
      end
    end
  end

  def sitters
    @sitters ||= Sitter.all[0...InitialSitterCount]
  end

  def sitters=(sitters)
    self.willChangeValueForKey :sitters
    @sitters = sitters
    self.didChangeValueForKey :sitters

    self.willChangeValueForKey :suggested_sitters
    @suggested_sitters = nil
    self.suggested_sitters # for effect
    self.didChangeValueForKey :suggested_sitters
  end

  def suggested_sitters
    @suggested_sitters ||= Sitter.all - sitters
  end

  def setSitterCount(count)
    delta = count - self.sitters.length
    case
    when delta < 0 then self.sitters = self.sitters[0...count]
    when 0 < delta then self.sitters = self.sitters + self.suggested_sitters[0...delta]
    end
  end

  def canAddSitter(sitter)
    return self.sitters.length < MaxSitterCount && !self.sitters.include?(sitter)
  end

  def addSitter(sitter)
    return unless self.canAddSitter(sitter)
    # instead of <<, for KVO
    self.sitters = self.sitters + [sitter]
  end
end
