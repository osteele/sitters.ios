class SettingsController < Formotion::FormController
  def initWithNibName(name, bundle:bundle)
    super
    self.tap do
      self.tabBarItem = UITabBarItem.alloc.initWithTitle('Settings', image:UIImage.imageNamed('tabs/settings.png'), tag:5)
    end
  end

  def submit
    data = self.form.render
    # puts data[:settings][:arc_text]
  end

  def self.form
    Formotion::Form.new({
      # persist_as: :settings,
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
        }, {
          title: 'Sitter',
          value: true,
          key: :basic,
          type: :check,
        }]
      # }, {
      #   title: 'Settings',
      #   key: :settings,
      #   rows: [{
      #     title: 'Arc Text',
      #     key: :arc_text,
      #     type: :switch,
      #     value: NSUserDefaults.standardUserDefaults[:arc_text],
      #   }]
      # }, {
      #   rows: [{
      #     title: 'Save',
      #     type: :submit,
      # }]
      }]
    })
  end
end
