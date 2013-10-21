ENV['PX_STYLESHEET_PATH'] = File.join(File.dirname(__FILE__), 'resources/default.css')

Motion::Project::App.setup do |app|
  app.pixate.user = 'steele@osteele.com'
  app.pixate.key  = 'N0NMP-P5L6B-PM1IO-5ERQA-SBGQA-NIVLU-99FAB-O41MU-H9DII-4IUJ8-0T3D6-F2SFP-8PPM9-A6C1P-BUS7N-1C'
  app.pixate.framework = 'vendor/Pixate.framework'
end
