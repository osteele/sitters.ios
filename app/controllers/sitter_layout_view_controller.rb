class SitterLayoutdViewController < UIViewController
  def viewDidLoad
    super
    @scroll.frame = self.view.bounds
    @scroll.contentSize = CGSizeMake(@scroll.frame.size.width, @scroll.frame.size.height + 320)
  end

  layout do
    view.styleId = :sitter_profile

    @scroll = subview UIScrollView.alloc.initWithFrame(self.view.bounds) do
      # subview UIView, styleClass: :section, styleId: :name_section do
      subview UILabel, styleId: :name, text: 'Kristen Morey'
      subview UITextView, styleId: :description, text: 'Susie Morey’s 14-year-old sister. Currently a freshman at Palo Alto High School'

      subview UIView, styleClass: :section, styleId: :age do
        subview UILabel, styleClass: :title, text: 'Age'
        subview UITextView, styleClass: :description, text: '14 years'
      end

      subview UIView, styleClass: :section, styleId: :experience do
        subview UILabel, styleClass: :title, text: 'Experience'
        subview UILabel, styleClass: :description, text: '2 years'
      end

      subview UIView, styleClass: :section, styleId: :endorsed_by do
        subview UILabel, styleId: :endorsed_by_title, styleClass: :title, text: 'Endorsed By'
        # TODO three movie circles
      end

      subview UIView, styleClass: :section, styleId: :used_by do
        subview UILabel, styleClass: :title, text: 'Used By'
        # TODO five image circles
      end

      subview UIView, styleClass: :section, styleId: :background_check do
        subview UILabel, styleClass: :title, text: 'Background Check'
        subview UITextView, styleClass: :description, text: 'Cleared'
      end

      subview UIView, styleClass: :section, styleId: :location do
        subview UILabel, styleClass: :title, text: 'Location'
        subview UITextView, styleClass: :description, text: 'Palo Alto'
      end

      # TODO this one needs to be resizable. Something to use besides UILabel?
      subview UIView, styleClass: :section, styleId: :about_me do
        subview UILabel, styleClass: :title, text: 'About Me'
        subview UITextView, styleClass: :description, text: 'I grew up in Palo Alto etc. etc.'
      end

      subview UIView, styleClass: :section, styleId: :smoker do
        subview UILabel, styleClass: :title, text: 'Smoker'
        subview UITextView, styleClass: :description, text: 'No'
      end

      subview UIView, styleClass: :section, styleId: :transport do
        subview UILabel, styleClass: :title, text: 'Transport'
        subview UITextView, styleClass: :description, text: 'None'
      end
    end

    subview UIView, styleId: :header do
      subview UILabel, styleClass: :date, text: 'Sunday, September 22'
      subview UILabel, styleClass: :hours, text: '6:00–9:00 PM'
    end

    subview UILabel, styleId: :footer, text: 'Add to My Seven Sitters'
  end
end
