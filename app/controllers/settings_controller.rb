class SettingsController < Formotion::FormController
  def initWithNibName(name, bundle:bundle)
    super
    self.tap do
      self.tabBarItem = UITabBarItem.alloc.initWithTitle('Settings', image:UIImage.imageNamed('tabs/settings'), tag:5)
    end
  end

  def viewDidDisappear(view)
    data = self.form.render
    Sitter.setAddedCount(data[:sitter_count].to_i)
  end

  def self.form
    buildDate = UIApplication.sharedApplication.delegate.buildDate
    expirationDate = UIApplication.sharedApplication.delegate.expirationDate
    dateFormatter = NSDateFormatter.alloc.init.setDateStyle(NSDateFormatterShortStyle)
    dateTimeFormatter = NSDateFormatter.alloc.init.setDateStyle(NSDateFormatterShortStyle).setTimeStyle(NSDateFormatterShortStyle)

    Formotion::Form.new({
      sections: [{
        title: 'Registration',
        rows: [{
          title: 'Email',
          key: :email,
          placeholder: 'me@mail.com',
          type: :email,
          auto_correction: :no,
          auto_capitalization: :none
        }]
      }, {
        title: 'Account Type',
        key: :account_type,
        select_one: true,
        rows: [{
          title: 'Parent',
          key: :free,
          type: :check,
          value: true
        }, {
          title: 'Sitter',
          key: :basic,
          type: :check,
        }],
      }, {
        title: 'About',
        rows: [
        {
          title: 'Build time',
          type: :static,
          value: dateTimeFormatter.stringFromDate(buildDate)
        },
        {
          title: 'Expiration date',
          type: :static,
          value: expirationDate ? dateFormatter.stringFromDate(expirationDate) : 'Never'
        }]
      }, {
        title: 'Debug',
        rows: [{
          title: 'Sitters',
          key: :sitter_count,
          type: :options,
          items: (0..7).map { |n| n.to_s },
          value: Sitter.added.length.to_s
        }]
        # {
        #   title: 'Arc Text',
        #   key: :arc_text,
        #   type: :switch,
        #   value: NSUserDefaults.standardUserDefaults[:arc_text],
        # }
      }]
    })
  end
end
