Motion::SettingsBundle.setup do |app|
  app.title 'Build version', key: 'buildVersion', default: BUILD_VERSION
  app.title 'Build date', key: 'buildDate', default: BUILD_DATE.strftime('%I:%M %p %x')

  app.child 'Debug' do |section|
    section.toggle 'Slow animation', key: 'slowAnimation', default: false
    section.toggle 'Emulate server', key: 'emulateServer', default: true
  end
end
