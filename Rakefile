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

FB_APP_ID = ENV.require('FB_APP_ID')

Motion::Project::App.setup do |app|
  set_provisioning_profile app

  app.identifier = 'com.sevensitters.sevensitters'
  app.name = 'Seven Sitters'
  # app.seed_id = ENV.require('IOS_APP_ID')
  app.short_version = BUILD_VERSION
  app.version = BUILD_VERSION
  app.icons = ['Icon.png', 'Icon@2x.png', 'Icon-Small.png', 'Icon-Small@2x.png']
  app.interface_orientations = [:portrait]
  # app.entitlements['keychain-access-groups'] = ["#{app.seed_id}.#{app.identifier}"]

  app.info_plist['BuildDate'] = BUILD_DATE.iso8601
  # app.info_plist['ExpirationDate'] = (now + 5).strftime('%Y-%m-%dT%H:%M:%S%z')
  # app.info_plist['UIStatusBarStyle'] = 'UIStatusBarStyleBlackTranslucent'
  for token_name in ['TESTFLIGHT_APP_TOKEN']
    app.info_plist[token_name] = ENV[token_name] if ENV[token_name]
  end

  app.vendor_project 'lib/OSUtils', :static
  app.vendor_project 'vendor/BlockBuilder', :static

  app.pods do
    pod 'Facebook-iOS-SDK'
    pod 'FMDB'
    pod 'GRMustache'
    pod 'NSDate-Extensions'
    pod 'ReactiveCocoa'
    pod 'TestFlightSDK'
  end
  app.weak_frameworks += %w(AdSupport Social)

  app.info_plist['FacebookAppID'] = FB_APP_ID
  app.info_plist['FacebookAppId'] = FB_APP_ID # works around bug in FB SDK
  app.info_plist['FacebookDisplayName'] = 'Seven Sitters'
  app.info_plist['URL types'] = [{'URL Schemes' => ["fb#{FB_APP_ID}"]}]

  sh "grunt update"
end
