PROFILE_HOME = File.expand_path('~/Library/MobileDevice/Provisioning Profiles')

Motion::Project::App.setup do |app|
  app.development do
    PROFILE_IDENTIFER_NAME = 'IOS_APP_DEVELOPMENT_PROFILE_ID'
  end

  app.release do
    PROFILE_IDENTIFER_NAME = 'IOS_APP_PRODUCTION_PROFILE_ID'
    app.entitlements['get-task-allow'] = false
  end

  profiles = Dir[File.join(PROFILE_HOME, '*.mobileprovision')]
  profile_path = profiles.first if profiles.length == 1
  unless profile_path
    die "#{PROFILE_IDENTIFER_NAME} must be defined" unless PROFILE_IDENTIFER = ENV[PROFILE_IDENTIFER_NAME]
    profile_path = File.join(PROFILE_HOME, "#{PROFILE_IDENTIFER}.mobileprovision")
  end
  app.provisioning_profile = profile_path
end
