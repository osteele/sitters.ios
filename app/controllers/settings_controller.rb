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
    card = STPCard.alloc.init
    card.number = info.cardNumber
    card.expMonth = info.expiryMonth
    card.expYear = info.expiryYear
    card.cvc = info.cvv
    progress = SVProgressHUD.showWithStatus "Validating Card", maskType:SVProgressHUDMaskTypeBlack
    Stripe.createTokenWithCard card, success:->token {
      Logger.info "Token created with ID: %@", token.tokenId
      cardType = CardIOCreditCardInfo.displayStringForCardType(info.cardType, usingLanguageOrLocale:NSLocale.currentLocale.localeIdentifier)
      Account.instance.cardInfo = {cardType:cardType, last4: info.cardNumber[/.{4}$/], expirationMonth:info.expiryMonth, expirationYear:info.expiryYear}
      Server.instance.registerPaymentToken token.tokenId, Account.instance.cardInfo
      updateForm
      progress.showSuccessWithStatus 'Validation Succeeded'
      self.dismissViewControllerAnimated true, completion: nil
      App.run_after(1) { progress.dismiss }
    }, error:->error {
      self.dismissViewControllerAnimated true, completion: nil
      progress.dismiss
      App.alert 'Card Error', message:error.localizedDescription
    }
  end

  private

  def updateForm
    self.form = createForm
    @form.controller = self
    self.tableView.reloadData
  end

  def createForm
    app = App.delegate
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
      end
    end

    form.build_section do |section|
      section.title = 'Payment'
      if Account.instance.cardInfo
        section.build_row do |row|
          row.type = :static
          puts "build #{Account.instance.cardInfo}"
          info = Account.instance.cardInfo
          row.title = "#{info[:cardType]} •••• #{info[:last4]}"
        end
        section.build_row do |row|
          row.title = 'Remove card'
          row.type = :button
          row.key = :remove_payment_card
        end
      else
        section.build_row do |row|
          row.title = 'Add credit card'
          row.type = :button
          row.key = :enter_payment_card
        end
      end
    end if user

    form.row(:logout).on_tap do |row|
      account.logout
    end if form.row(:logout)

    form.row(:enter_payment_card).on_tap do |row|
      Logger.checkpoint 'Enter payment card'
      cardController ||= CardIOPaymentViewController.alloc.initWithPaymentDelegate(self)
      cardioAppToken = NSBundle.mainBundle.objectForInfoDictionaryKey('CardioAppToken')
      cardController.appToken = cardioAppToken if cardioAppToken
      self.presentViewController cardController, animated:true, completion:nil
    end if form.row(:enter_payment_card)

    form.row(:remove_payment_card).on_tap do |row|
      Logger.checkpoint 'Remove payment card'
      Server.instance.removePaymentCard Account.instance.cardInfo
      Account.instance.cardInfo = nil
      updateForm
    end if form.row(:remove_payment_card)

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
