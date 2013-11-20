class SettingsController < Formotion::FormController
  include BW::KVO

  def init
    self.initWithForm(createForm)
  end

  def initWithNibName(name, bundle:bundle)
    super
    self.tap do
      self.tabBarItem = UITabBarItem.alloc.initWithTitle('Settings', image:UIImage.imageNamed('tabs/settings'), tag:5)
      observe(Account.instance, :user) do updateForm end
      observe(Family.instance, :sitters) do updateForm end
    end
  end

  def viewDidDisappear(view)
    data = self.form.render
    Server.instance.setSitterCount(data[:sitter_count].to_i)
  end

  def userDidCancelPaymentViewController(scanViewController)
    self.dismissViewControllerAnimated true, completion: nil
  end

  def userDidProvideCreditCardInfo(info, inPaymentViewController:scanViewController)
    # NSLog "info = %@", info
    self.dismissViewControllerAnimated true, completion: nil
  end

  private

  def updateForm
    self.form = createForm
    @form.controller = self
    self.tableView.reloadData
  end

  def createForm
    app = UIApplication.sharedApplication.delegate
    form = Formotion::Form.new

    account = Account.instance
    user = account.user

    form.build_section do |section|
      section.title = 'Account'
      if user
        section.build_row do |row|
          row.title = 'Sign Out'
          row.type = :button
          row.key = :logout
        end
        section.build_row do |row|
          row.type = :static
          row.title = user.displayName
        end
        section.build_row do |row|
          row.type = :static
          row.title = user.locationName
        end if user.locationName
      else
        section.build_row do |row|
          row.title = 'Sign In'
          row.type = :button
          row.key = :login
        end
      end
    end

    form.build_section do |section|
      section.title = 'Payment'
      section.build_row do |row|
        row.title = 'Enter payment information'
        row.type = :button
        row.key = :payment
      end
    end if user #and false

    form.row(:login).on_tap do |row|
      account.login
    end if form.row(:login)

    form.row(:logout).on_tap do |row|
      account.logout
    end if form.row(:logout)

    form.row(:payment).on_tap do |row|
      Logging.breadcrumb "Enter card info"
      cardio ||= CardIOPaymentViewController.alloc.initWithPaymentDelegate(self)
      cardioAppToken = NSBundle.mainBundle.objectForInfoDictionaryKey('CardioAppToken')
      cardio.appToken = cardioAppToken if cardioAppToken
      self.presentViewController cardio, animated:true, completion:nil
    end if form.row(:payment)

    if false
      buildDate = app.buildDate
      expirationDate = ExpirationChecker.instance.expirationDate
      dateFormatter = NSDateFormatter.alloc.init.setDateStyle(NSDateFormatterMediumStyle)
      dateTimeFormatter = NSDateFormatter.alloc.init.setDateStyle(NSDateFormatterMediumStyle).setTimeStyle(NSDateFormatterShortStyle)

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
    end

    form.build_section do |section|
      section.title = 'Demo'
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
