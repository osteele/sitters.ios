# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'
require "rubygems"
require 'bundler'
Bundler.require

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.identifier = "com.sevensitters.sevensitters"
  app.name = "Seven Sitters"
  # app.device_family = :iphone
  # app.icons = ['']
  app.interface_orientations = [:portrait]

  app.development do
    app.testflight do
      app.testflight.sdk = 'vendor/TestFlight'
      app.testflight.api_token = ENV['TF_API'] or throw "$TF_API required"
      app.testflight.team_token = ENV['TF_TT'] or throw "$TF_TT required"
      # app.testflight.distribution_lists = ['Staff']
    end
  end
end
