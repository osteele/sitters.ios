class SitterProfileEditController < UIViewController
  include BW::KVO
  extend IB

  outlet :birthDate, UIButton
  outlet :description, UITextView
  outlet :fullName, UILabel

  ib_action :signOutButtonTouched

  def viewDidLoad
    NSLog "SitterProfileEditController.viewDidLoad"
    updateFieldsFromAccountInfo
    observe(Account.instance, :user) do |_, value|
      updateFieldsFromAccountInfo
    end
  end

  def updateFieldsFromAccountInfo
    user = Account.instance.user
    return unless user
    self.fullName.text = user.displayName || 'First Last'
    s = (user.birthdayString || '—')
    self.birthDate.setTitle s, forState:UIControlStateNormal
  end

  def signOutButtonTouched(view)
    NSLog 'signout from sitter profile'
    Account.instance.logout
  end
end
