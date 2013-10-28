Motion::SettingsBundle.setup do |app|
  app.title 'Build version', key: :build_date, default: BUILD_VERSION
  app.title 'Build date', key: :build_date, default: BUILD_DATE.strftime('%H:%M %b %d, %Y')
end
