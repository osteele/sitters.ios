# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'
require "rubygems"
require 'bundler'
Bundler.require

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'Seven Sitters'

  app.testflight.sdk = 'vendor/TestFlight'
  app.testflight.api_token = ENV['TF_API'] or throw "$TF_API required"
  app.testflight.team_token = ENV['TF_TT'] or throw "$TF_TT required"
  # app.testflight.distribution_lists = ['Staff']
end
