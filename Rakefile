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
require_all 'config'
require_all 'tasks'

Motion::Project::App.setup do |app|
  app.identifier = 'com.sevensitters.sevensitters'
  app.name = 'Seven Sitters'
  app.short_version = app.version = BUILD_VERSION
  app.icons = ['Icon.png', 'Icon@2x.png', 'Icon-Small.png', 'Icon-Small@2x.png']
  app.interface_orientations = [:portrait]

  app.info_plist['BuildDate'] = BUILD_DATE.iso8601
  # app.info_plist['ExpirationDate'] = (now + 5).strftime('%Y-%m-%dT%H:%M:%S%z')
  for token_name in ['TF_APP_TOKEN']
    app.info_plist[token_name] = ENV[token_name] if ENV[token_name]
  end

  app.vendor_project 'vendor/TestFlight', :static

  # TestFlight:
  libz = '/usr/lib/libz.dylib'
  app.libs << libz unless app.libs.include?(libz)

  # Firebase:
  # app.vendor_project 'vendor/Firebase.framework', :static, :products => ['Firebase'] ,:headers_dir => 'Headers'
  # app.libs += ['/usr/lib/libicucore.dylib']
  # app.frameworks += ['CFNetwork', 'Security', 'SystemConfiguration']

  # Firebase simple login:
  # app.vendor_project 'vendor/FirebaseSimpleLogin.framework', :static, :products => ['FirebaseSimpleLogin'] ,:headers_dir => 'Headers'
  # app.frameworks += ['Accounts', 'Social']

  app.vendor_project 'lib/OSUtils', :static
  app.vendor_project 'vendor/BlockBuilder', :static

  app.pods do
    pod 'Firebase', '~> 1.0.0'
    # pod "Facebook-iOS-SDK"
    pod 'FMDB'
    pod 'GRMustache'
    pod 'NSDate-Extensions'
    pod 'ReactiveCocoa'
  end
  app.weak_frameworks += %w(AdSupport Social)

  set_provisioning_profile app

  # app.entitlements['keychain-access-groups'] = ["#{app.seed_id}.#{app.identifier}"]
  FB_APP_ID = ENV['FB_APP_ID']
  app.info_plist['FacebookAppID'] = FB_APP_ID
  app.info_plist['FacebookDisplayName'] = 'Seven Sitters'
  app.info_plist['URL types'] = [{'URL Schemes' => ["fb#{FB_APP_ID}"]}]

  sh "grunt update"
end
