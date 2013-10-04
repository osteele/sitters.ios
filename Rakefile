# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'
require "rubygems"
require 'bundler'
Bundler.require

ENV['PX_STYLESHEET_PATH'] = File.join(File.dirname(__FILE__), 'resources/default.css')

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.identifier = "com.sevensitters.sevensitters"
  app.name = "Seven Sitters"
  # app.device_family = :iphone
  # app.icons = ['']
  app.interface_orientations = [:portrait]

  app.pixate.user = 'steele@osteele.com'
  app.pixate.key  = 'N0NMP-P5L6B-PM1IO-5ERQA-SBGQA-NIVLU-99FAB-O41MU-H9DII-4IUJ8-0T3D6-F2SFP-8PPM9-A6C1P-BUS7N-1C'
  app.pixate.framework = 'vendor/Pixate.framework'

  app.development do
    app.testflight do
      app.testflight.sdk = 'vendor/TestFlight'
      app.testflight.api_token = ENV['TF_API'] or throw "$TF_API required"
      app.testflight.team_token = ENV['TF_TT'] or throw "$TF_TT required"
      # app.testflight.distribution_lists = ['Staff']
    end
  end
end
