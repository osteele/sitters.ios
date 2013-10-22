# -*- coding: utf-8 -*-
require 'json'
require 'launchy'
require 'rest_client'

TF_ENDPOINT = 'http://testflightapp.com/api/builds.json'

task :testflight => 'testflight:upload'

namespace :testflight do
  task :upload => 'archive:distribution' do
    release_note_path = File.join(File.dirname(__FILE__), '../RELEASE.txt')
    die "#{release_note_path} must exist" unless File.exists?(release_note_path)
    release_notes = File.read(release_note_path)
    payload = {
      :api_token  => ENV.require('TF_API_TOKEN'),
      :team_token => ENV.require('TF_TEAM_TOKEN'),
      :file       => open(App.config.archive, 'rb'),
      :notes      => release_notes,
      # dsym:
      :distribution_lists => ['Oliver'],
      :notify             => false,
    }

    response = RestClient.post(TF_ENDPOINT, payload, :accept => :json) rescue $!.response
    die "Upload failed: #{response}" unless [200, 201].include?(response.code)
    Launchy.open JSON.parse(response.body)['config_url']
  end
end
