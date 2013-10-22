PROFILE_HOME = File.expand_path('~/Library/MobileDevice/Provisioning Profiles')

def set_provisioning_profile_to(app, identifier)
  profiles = Dir[File.join(PROFILE_HOME, '*.mobileprovision')]
  profile_path = File.join(PROFILE_HOME, "#{identifier}.mobileprovision")
  puts "Setting provisioning profile = #{profile_path}"
  app.provisioning_profile = profile_path
end

# Motion::Project::App.setup do |app|
def set_provisioning_profile(app)
  app.development do
    set_provisioning_profile_to app, ENV.require('IOS_APP_DEVELOPMENT_PROFILE_ID')
    # set_provisioning_profile_to app, ENV.require('IOS_APP_PRODUCTION_PROFILE_ID')
  end

  app.release do
    set_provisioning_profile_to app, ENV.require('IOS_APP_PRODUCTION_PROFILE_ID')
    app.entitlements['get-task-allow'] = false
  end
end
