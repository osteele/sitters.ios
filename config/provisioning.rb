PROFILE_HOME = File.expand_path('~/Library/MobileDevice/Provisioning Profiles')

def get_provisioning_profile_for(identifier)
  profiles = Dir[File.join(PROFILE_HOME, '*.mobileprovision')]
  return File.join(PROFILE_HOME, "#{identifier}.mobileprovision")
end

# This method has already been called by the time a Motion::Project::App.setup block is entered,
# and fails if no profile named iOS Team exists.
module Motion; module Project;
  class IOSConfig < XcodeConfig
    def provisioning_profile(name=nil)
      return get_provisioning_profile_for(ENV.require('IOS_APP_DEVELOPMENT_PROFILE_ID'))
    end
  end
end; end

# Can't use Motion::Project::App.setup because it runs before archive:distribution sets the build mode
def set_provisioning_profile(app)
  app.development do
    app.provisioning_profile = get_provisioning_profile_for(ENV.require('IOS_APP_DEVELOPMENT_PROFILE_ID'))
    app.entitlements['get-task-allow'] = true
  end

  app.release do
    app.provisioning_profile = get_provisioning_profile_for(ENV.require('IOS_APP_PRODUCTION_PROFILE_ID'))
    app.codesign_certificate = ENV[IOS_CODESIGN_CERTIFICATE] if ENV[IOS_CODESIGN_CERTIFICATE]
    app.entitlements['get-task-allow'] = false
  end
end
