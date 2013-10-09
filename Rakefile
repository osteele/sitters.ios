# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'
require "rubygems"
require 'bundler'
Bundler.require

Dotenv.load

PROFILE_HOME = File.expand_path('~/Library/MobileDevice/Provisioning Profiles')
ENV['PX_STYLESHEET_PATH'] = File.join(File.dirname(__FILE__), 'resources/default.css')
require File.join(File.dirname(__FILE__), 'config/settings.rb')

Motion::Project::App.setup do |app|
  app.identifier = 'com.sevensitters.sevensitters'
  app.name = 'Seven Sitters'
  app.short_version = app.version = '0.1.6'
  app.icons = ['icon-120.png']
  app.interface_orientations = [:portrait]

  app.pixate.user = 'steele@osteele.com'
  app.pixate.key  = 'N0NMP-P5L6B-PM1IO-5ERQA-SBGQA-NIVLU-99FAB-O41MU-H9DII-4IUJ8-0T3D6-F2SFP-8PPM9-A6C1P-BUS7N-1C'
  app.pixate.framework = 'vendor/Pixate.framework'

  for token_name in ['TF_APP_TOKEN']
    app.info_plist[token_name] = ENV[token_name] if ENV[token_name]
  end

  app.vendor_project 'vendor/TestFlight', :static

  libz = '/usr/lib/libz.dylib'
  app.libs << libz unless app.libs.include?(libz)

  app.pods do
    pod 'NSDate-Extensions'
  end

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

  sh "grunt build"
end

def die(message)
  STDERR.puts message
  exit 1
end
