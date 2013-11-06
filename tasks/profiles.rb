gem 'launchy'

desc 'Show the provisioning profile directory'
task :profiles => 'profiles:open'

namespace :profiles do
  task :open do
    Launchy.open PROFILE_HOME
  end
end

