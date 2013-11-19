Motion::SettingsBundle.setup do |app|
  app.title 'Version', key: 'buildVersion', default: BUILD_VERSION
  app.title 'Build date', key: 'buildDate', default: BUILD_DATE.strftime('%I:%M %p %x')
  # app.group "Built on #{BUILD_DATE.strftime('%I:%M %p %x')}."

  app.child 'Debug' do |section|
    section.toggle 'Use development server', key: 'useDevelopmentServer', default: false
    # section.group "Enable this to run against the development server. Only do this if you're coding the app."

    section.toggle 'Run micro-server on phone', key: 'emulateServer', default: true
    # section.group "Emulate the server locally instead of using one on the other side of a network. Good for demos."

    section.toggle 'Simulate confirmation delay', key: 'simulateSitterConfirmationDelay', default: true
    # section.group "Simulated sitters delay before responding. Only applies to local micro-server."

    section.toggle 'Slow animation', key: 'slowAnimation', default: false
  end
end
