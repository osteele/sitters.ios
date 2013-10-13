require 'rest_client'
require 'json'

TF_ENDPOINT = 'http://testflightapp.com/api/builds.json'

namespace :testflight do
  task :upload => 'archive:distribution' do
    payload = {
      :api_token  => ENV['TF_API'] || die('TF_API'),
      :team_token => ENV['TF_TT'] || die('TF_TT'),
      :file       => App.config.app_bundle('iPhoneOS'),
      :notes      => File.read(File.join(File.dirname(__FILE__), '../RELEASE.txt')),
      # dsym:
    }
    p payload
    response = RestClient.post(TF_ENDPOINT, payload, :accept => :json)
    # 'config_url', 'install_url'
    # p response
    puts response['config_url']
  end
end
