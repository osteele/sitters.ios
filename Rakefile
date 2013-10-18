# -*- coding: utf-8 -*-
$:.unshift('/Library/RubyMotion/lib')
require 'motion/project/template/ios'
require 'rubygems'
require 'bundler'
require 'date'
Bundler.require

Dotenv.load
require File.join(File.dirname(__FILE__), 'config/settings.rb')
require_all 'tasks'

PROFILE_HOME = File.expand_path('~/Library/MobileDevice/Provisioning Profiles')
ENV['PX_STYLESHEET_PATH'] = File.join(File.dirname(__FILE__), 'resources/default.css')

Motion::Project::App.setup do |app|
  app.identifier = 'com.sevensitters.sevensitters'
  app.name = 'Seven Sitters'
  app.short_version = app.version = '0.1.9'
  app.icons = ['icon-120.png']
  app.interface_orientations = [:portrait]

  app.pixate.user = 'steele@osteele.com'
  app.pixate.key  = 'N0NMP-P5L6B-PM1IO-5ERQA-SBGQA-NIVLU-99FAB-O41MU-H9DII-4IUJ8-0T3D6-F2SFP-8PPM9-A6C1P-BUS7N-1C'
  app.pixate.framework = 'vendor/Pixate.framework'

  now = DateTime.now
  app.info_plist['BUILD_DATE'] = now.strftime('%Y-%m-%dT%H:%M:%S%z')
  app.info_plist['EXPIRATION_DATE'] = (now + 5).strftime('%Y-%m-%dT%H:%M:%S%z')
  for token_name in ['TF_APP_TOKEN']
    app.info_plist[token_name] = ENV[token_name] if ENV[token_name]
  end

  app.vendor_project 'vendor/TestFlight', :static

  # TestFlight:
  libz = '/usr/lib/libz.dylib'
  app.libs << libz unless app.libs.include?(libz)

  # Firebase:
  # app.vendor_project('vendor/Firebase.framework', :static, :products => ['Firebase'] ,:headers_dir => 'Headers')
  # app.libs += ['/usr/lib/libicucore.dylib']
  # app.frameworks += ['CFNetwork', 'Security', 'SystemConfiguration']

  # Firebase simple login:
  # app.vendor_project('vendor/FirebaseSimpleLogin.framework', :static, :products => ['FirebaseSimpleLogin'] ,:headers_dir => 'Headers')
  # app.frameworks += ['Accounts', 'Social']

  app.pods do
    pod 'Firebase', '~> 1.0.0'
    # pod "Facebook-iOS-SDK"
    pod 'GRMustache'
    pod 'NSDate-Extensions'
  end
  app.weak_frameworks += %w(AdSupport Social)

  # app.entitlements['keychain-access-groups'] = ["#{app.seed_id}.#{app.identifier}"]
  FB_APP_ID = ENV['FB_APP_ID']
  app.info_plist['FacebookAppID'] = FB_APP_ID
  app.info_plist['FacebookDisplayName'] = 'Seven Sitters'
  app.info_plist['URL types'] = [{'URL Schemes' => ["fb#{FB_APP_ID}"]}]

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

  sh "grunt update"
end

def die(message)
  STDERR.puts message
  exit 1
end
