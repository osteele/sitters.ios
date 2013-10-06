# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'
require "rubygems"
require 'bundler'
Bundler.require

ENV['PX_STYLESHEET_PATH'] = File.join(File.dirname(__FILE__), 'resources/default.css')

Motion::Project::App.setup do |app|
  app.identifier = 'com.sevensitters.sevensitters'
  app.name = 'Seven Sitters'
  app.short_version = app.version = '0.1.2'
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

  app.release do
    app.entitlements['get-task-allow'] = false
  end

  sh "grunt build"
end
