class SittersController < UIViewController
  include BW::KVO
  stylesheet :sitters

  attr_accessor :selectedTimeSpan

  def initWithNibName(name, bundle:bundle)
    super
    self.tap do
      self.tabBarItem = UITabBarItem.alloc.initWithTitle('Sitters', image:UIImage.imageNamed('tabs/sitters.png'), tag:1)
    end
  end

  def viewDidLoad
    super
    fudge = 70
    @scrollView.frame = self.view.bounds
    @scrollView.contentSize = CGSizeMake(@scrollView.frame.size.width, @scrollView.frame.size.height + fudge)

    self.view.stylesheet = :sitters
    self.view.stylename = :sitters

    today = NSDate.date.dateAtStartOfDay
    self.selectedTimeSpan = TimeSpan.new(today, 18, 21)
  end

  layout do
    view.styleId = :sitters

    mySittersController = MySittersController.alloc.init
    mySittersController.outerController = self
    self.addChildViewController mySittersController
    @currentSittersView = mySittersController.view

    observe(self, :selectedTimeSpan) do mySittersController.selectedTimeSpan = selectedTimeSpan end

    # nav = UINavigationController.alloc.initWithRootViewController(mySittersController)
    # mySittersController.view.frame = [[0, 140], [320, 700]]
    # nav.navigationItem.titleView.setHidden true

    @scrollView = subview UIScrollView.alloc.initWithFrame(self.view.bounds) do
      subview mySittersController.view
      # subview nav.view
      # @currentSittersView.size = @currentSittersView.sizeThatFits(CGSizeZero)
    end

    createTimeSelector
  end

  def presentAddSitterView
    @addSitterController ||= AddSitterController.alloc.init
    @suggestedSitterListView ||= begin
      view = subview UIView, left: 320, top: 140, width: 320, height: 500 do
        back = subview UILabel, left:0, top:0, width:320, height:20, text:' < Sitters', color:UIColor.blueColor
        back.when_tapped { returnFromAddSitterView }
        list = subview @addSitterController.view
        # list.when_tapped { presentSitterDetails }
      end
      view
    end
    @scrollView.insertSubview @suggestedSitterListView, belowSubview:@timeSelectorView
    UIView.animateWithDuration 0.3, animations: lambda {
      @currentSittersView.origin = [-320, @currentSittersView.origin.y]
      @suggestedSitterListView.origin = [0, @suggestedSitterListView.origin.y]
    }
  end

  private

  def returnFromAddSitterView
    @scrollView.insertSubview @currentSittersView, belowSubview:@timeSelectorView
    UIView.animateWithDuration 0.3, animations: lambda {
      @currentSittersView.origin = [0, @currentSittersView.origin.y]
      @suggestedSitterListView.origin = [320, @suggestedSitterListView.origin.y]
    }
  end

  def presentSitterDetails
    @sitterDetailsController ||= SitterDetailsController.alloc.init
    @sitterDetailsView ||= begin
      view = subview UIView, left: 320, top: 140, width: 320, height: 800 do
        back = subview UILabel, left:0, top:0, width:320, height:20, text:' < Add Sitter', color:UIColor.blueColor
        back.when_tapped { returnFromSitterDetailsView }
        subview @sitterDetailsController.view
      end
    end
    @scrollView.insertSubview @sitterDetailsView, belowSubview:@timeSelectorView
    UIView.animateWithDuration 0.3, animations: lambda {
      @suggestedSitterListView.origin = [-320, @suggestedSitterListView.origin.y]
      @sitterDetailsView.origin = [0, @sitterDetailsView.origin.y]
    }
  end

  def returnFromSitterDetailsView
    UIView.animateWithDuration 0.3, animations: lambda {
      @suggestedSitterListView.origin = [0, @suggestedSitterListView.origin.y]
      @sitterDetailsView.origin = [320, @sitterDetailsView.origin.y]
    }
  end
end

class MySittersController < UIViewController
  include BW::KVO
  stylesheet :sitters
  attr_accessor :outerController
  attr_accessor :selectedTimeSpan

  layout do
    view.styleId = :sitters

    createSitterAvatars

    viewRecommendedButton = subview UIButton, styleId: :recommended, styleClass: :big_button do
      subview UILabel, text: 'View Recommended'
      subview UILabel, styleClass: :caption, text: '14 connected sitters'
    end
    viewRecommendedButton.when_tapped { outerController.presentAddSitterView }

    subview UIButton, styleId: :invite, styleClass: :big_button do
      subview UILabel, text: 'Invite a Sitter'
      subview UILabel, styleClass: :caption, text: 'to add a sitter you know'
    end

    addSittersText = subview UIView do
      sitterCount = 2
      toSevenString = NSNumberFormatter.alloc.init.setNumberStyle(NSNumberFormatterSpellOutStyle).stringFromNumber(7 - 2)
      subview UILabel, styleId: :add_sitters, text: "Add #{toSevenString} more sitters"
      subview UILabel, styleId: :add_sitters_caption, text: 'to enjoy complete freedom and spontaneity.'
    end
    addSittersText.when_tapped { outerController.presentAddSitterView }
  end

  def createSitterAvatars
    cgMask = SitterCircle.maskImage

    sitters = Sitter.all[0...7]
    sitterViews = []
    view = subview UIView, styleId: :avatars, left: 10, top: 150, width: 300, height: 300 do
      for i in 0...7
        sitter = sitters[i]
        sitter.active = true
        view = subview SitterCircle, origin: sitter_positions[i], dataSource: sitter, dataIndex: i, styleClass: 'sitter' do
          subview UIImageView, image: sitter.maskedImage
          subview UIButton
          subview UILabel, text: (i+1).to_s
        end
        # view.when_tapped { puts 'tap sitter' }
        sitterViews << view
      end
      # view.when_tapped { presentAddSitterView }
    end

    observe(self, :selectedTimeSpan) do |_, timeSpan|
      UIView.animateWithDuration 0.3,
        animations: lambda {
          sitterViews.map do |view|
            alpha = if view.dataSource.availableAt(timeSpan) then 1 else 0.5 end
            view.alpha = alpha unless view.alpha == alpha
          end
        }
      end

    return view
  end

  def sitter_positions
    top = 0
    left1 = 70
    left2 = left1 - 48
    width = 96
    height = 84
    [
      [0, 0], [1, 0],
      [0, 1], [1, 1], [2, 1],
      [0, 2], [1, 2],
    ].map do |x, y|
      left = (if y == 1 then left2 else left1 end)
      [left + x * width, top + y * height]
    end
  end
end

Teacup::Stylesheet.new :sitters do
  style :right_dragger,
    left: '100%-20',
    top: 0,
    width: 40,
    height: '100%'
end
