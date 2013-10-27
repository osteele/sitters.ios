class SettingsController < Formotion::FormController
  include BW::KVO

  def initWithNibName(name, bundle:bundle)
    super
    self.tap do
      self.tabBarItem = UITabBarItem.alloc.initWithTitle('Settings', image:UIImage.imageNamed('tabs/settings'), tag:5)
      observe(Account.instance, :user) do update_form end
      observe(Family.instance, :sitters) do update_form end
    end
  end

  def viewDidDisappear(view)
    data = self.form.render
    Family.instance.setSitterCount(data[:sitter_count].to_i)
  end

  def update_form
    self.form = self.class.form
    @form.controller = self
    self.tableView.reloadData
  end

  def self.form
    app = UIApplication.sharedApplication.delegate
    account = Account.instance
    user = account.user
    buildDate = app.buildDate
    expirationDate = ExpirationChecker.instance.expirationDate
    dateFormatter = NSDateFormatter.alloc.init.setDateStyle(NSDateFormatterShortStyle)
    dateTimeFormatter = NSDateFormatter.alloc.init.setDateStyle(NSDateFormatterShortStyle).setTimeStyle(NSDateFormatterShortStyle)

    form = Formotion::Form.new

    form.build_section do |section|
      section.title = 'Account'
      section.build_row do |row|
        row.title = 'Sign In'
        row.type = :button
        row.key = :login
      end unless user
      section.build_row do |row|
        row.title = 'Sign Out'
        row.type = :button
        row.key = :logout
      end if user
      section.build_row do |row|
        row.type = :static
        row.title = user.displayName
      end if user
      section.build_row do |row|
        row.type = :static
        row.title = user.locationName
      end if user and user.locationName
    end

    form.row(:login).on_tap do |row|
      account.login
    end if form.row(:login)

    form.row(:logout).on_tap do |row|
      account.logout
    end if form.row(:logout)

    form.build_section do |section|
      section.title = 'About'
      section.build_row do |row|
        row.title = 'Build'
        row.type = :static
        row.value = dateTimeFormatter.stringFromDate(buildDate)
      end
      section.build_row do |row|
        row.title = 'Expires'
        row.type = :static
        row.value = expirationDate ? dateTimeFormatter.stringFromDate(expirationDate) : 'Never'
      end if expirationDate
    end

    form.build_section do |section|
      section.title = 'Debug'
      section.build_row do |row|
        row.title = 'Sitters'
        row.type = :options
        row.key = :sitter_count
        row.items = (0..7).map { |n| n.to_s }
        row.value = Family.instance.sitters.length.to_s
      end
    end

    return form
  end
end
