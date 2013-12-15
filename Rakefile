# -*- coding: utf-8 -*-
$:.unshift('/Library/RubyMotion/lib')
require 'motion/project/template/ios'
require 'rubygems'
require 'bundler'
require 'date'
Bundler.require

Dotenv.load
BUILD_DATE = DateTime.now

require './version'
require_all 'tasks'
require_all 'config'

FACEBOOK_APP_ID = ENV.require('FACEBOOK_APP_ID') unless ENV['TRAVIS']

Motion::Project::App.setup do |app|
  # Name, version, and identifier
  app.identifier = 'com.sevensitters.sevensitters'
  app.name = 'Seven Sitters'
  # app.seed_id = ENV.require('IOS_APP_ID')
  app.short_version = BUILD_VERSION
  app.version = BUILD_VERSION

  # Authentication and entitlements
  set_provisioning_profile app unless ENV['TRAVIS']
  # app.entitlements['keychain-access-groups'] = ["#{app.seed_id}.#{app.identifier}"]

  # Interface
  app.icons = ['Icon.png', 'Icon@2x.png', 'Icon-Small.png', 'Icon-Small@2x.png']
  app.interface_orientations = [:portrait]
  # app.info_plist['UIStatusBarStyle'] = 'UIStatusBarStyleBlackTranslucent'

  app.info_plist['BuildDate'] = BUILD_DATE.iso8601

  # API Tokens
  for name in %w[CardioAppToken CrittercismAppId FacebookAppId MixpanelToken StripePublicKey TestflightAppToken]
    env_name = name.underscore.upcase
    env_value = ENV[env_name]
    if env_value
      app.info_plist[name.camelize] = env_value
    else
      puts "Warning: environment variable #{env_name} is undefined"
    end
  end

  app.pods do
    File.readlines('Podfile').select { |line| line =~ /^pod /}.each do |pod_line|
      eval pod_line
    end
  end

  # App
  app.weak_frameworks += %w[AddressBook AddressBookUI]
  app.vendor_project 'lib/OSUtils', :static

  # Crittercism
  app.frameworks += %w[SystemConfiguration]

  # Firebase Facebook Auth
  app.weak_frameworks += %w[AdSupport Social]

  # CardIO
  app.weak_frameworks += %w[AudioToolbox AVFoundation CoreGraphics CoreMedia CoreVideo Foundation MobileCoreServices OpenGLES QuartzCore Security UIKit]

  # ReactiveCocoa bridge
  app.vendor_project 'vendor/BlockBuilder', :static

  # Facebook
  unless ENV['TRAVIS']
    app.info_plist['FacebookAppID'] = FACEBOOK_APP_ID
    app.info_plist['FacebookAppId'] = FACEBOOK_APP_ID # works around bug in FB SDK
    app.info_plist['FacebookDisplayName'] = 'Seven Sitters'
    app.info_plist['URL types'] = [{'URL Schemes' => ["fb#{FACEBOOK_APP_ID}"]}]
  end

  sh "grunt update" unless ENV['SKIP_GRUNT']
end
