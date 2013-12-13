class WelcomeController < UIViewController
  extend IB

  outlet :greeting, UILabel # @property IBOutlet UILabel * title;
  ib_action :parentButtonTouched
  ib_action :sitterButtonTouched

  def parentButtonTouched(view)
    NSLog 'parent'
    App.delegate.presentMainController
  end

  def sitterButtonTouched(view)
    NSLog 'sitter'
  end
end
