class WelcomeController < UIViewController
  extend IB

  outlet :greeting, UILabel # @property IBOutlet UILabel * title;
  ib_action :parentButtonTouched
  ib_action :sitterButtonTouched

  def parentButtonTouched(view)
    NSLog 'touch parent'
    App.delegate.loginWithRole :parent
  end

  def sitterButtonTouched(view)
    NSLog 'touch sitter'
    App.delegate.loginWithRole :sitter
  end
end
