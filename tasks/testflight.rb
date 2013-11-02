# -*- coding: utf-8 -*-
require 'json'
require 'launchy'
require 'rest_client'

TESTFLIGHT_API_ENDPOINT = 'http://testflightapp.com/api/builds.json'

desc "Upload the application to TestFlight"
task :testflight => 'testflight:upload'

namespace :testflight do
  task :upload => 'archive:distribution' do
    release_note_path = File.join(File.dirname(__FILE__), '../RELEASE.txt')
    die "#{release_note_path} must exist" unless File.exists?(release_note_path)
    release_notes = File.read(release_note_path)
    payload = {
      :api_token  => ENV.require('TESTFLIGHT_API_TOKEN'),
      :team_token => ENV.require('TESTFLIGHT_TEAM_TOKEN'),
      :file       => open(App.config.archive, 'rb'),
      :notes      => release_notes,
      # dsym:
      :distribution_lists => ['Oliver'],
      :notify             => false,
    }

    response = RestClient.post(TESTFLIGHT_API_ENDPOINT, payload, :accept => :json) rescue $!.response
    die "Upload failed: #{response}" unless [200, 201].include?(response.code)
    Launchy.open JSON.parse(response.body)['config_url']
  end
end
