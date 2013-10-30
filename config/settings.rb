Motion::SettingsBundle.setup do |app|
  app.title 'Build version', key: 'buildVersion', default: BUILD_VERSION
  app.title 'Build date', key: 'buildDate', default: BUILD_DATE.strftime('%I:%M %p %x')
  app.toggle 'Animate time indicators', key: 'animateTimeIndicators', default: false
end
