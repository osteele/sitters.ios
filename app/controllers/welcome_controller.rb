class WelcomeController < UIViewController
  extend IB

  outlet :greeting, UILabel

  ib_action :parentButtonTouched
  ib_action :sitterButtonTouched

  def parentButtonTouched(view)
    App.delegate.loginWithRole :parent
  end

  def sitterButtonTouched(view)
    App.delegate.loginWithRole :sitter
  end

  def backFromEditSitterProfile(segue)
    NSLog 'backFromEditSitterProfile'
    Account.instance.logout
  end
end
