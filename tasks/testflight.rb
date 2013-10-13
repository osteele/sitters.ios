# -*- coding: utf-8 -*-
require 'rest_client'
require 'json'

TF_ENDPOINT = 'http://testflightapp.com/api/builds.json'

def require_env_variable(name)
  ENV[name] || die("The #{name} environment variable is required")
end

namespace :testflight do
  task :upload => 'archive:distribution' do
    release_note_path = File.join(File.dirname(__FILE__), '../RELEASE.txt')
    release_notes = File.read(release_note_path)
    payload = {
      :api_token  => require_env_variable('TF_API_TOKEN'),
      :team_token => require_env_variable('TF_TEAM_TOKEN'),
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
