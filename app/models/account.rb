class Account
  attr_accessor :user

  def self.instance
    Dispatch.once { @instance ||= new }
    @instance
  end

  def check
    auth.check do |error, user|
      self.user = user
    end
  end

  def auth
    app = UIApplication.sharedApplication.delegate
    @auth ||= FirebaseSimpleLogin.new(app.firebase)
  end

  def login
    auth.check do |error, user|
      if error or user
        authDidReturn user, error:error
      else
        permissions = ['email', 'read_friendlists', 'user_hometown', 'user_location', 'user_relationships']
        auth.login_to_facebook(app_id: '245805915569604', permissions: ['email']) do |error, user|
          authDidReturn user, error:error
        end
      end
    end
  end

  def logout
    auth.logout
    # TODO instead observe .info/authenticated
    self.user = nil
  end

  private

  def authDidReturn(user, error:error)
    self.user = user
    if error
      UIAlertView.alloc.initWithTitle(error.localizedDescription,
        message:error.localizedRecoverySuggestion,
        delegate:nil,
        cancelButtonTitle:'OK',
        otherButtonTitles:error.localizedRecoveryOptions).show
    end
  end
end
