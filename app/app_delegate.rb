class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    initializeTestFlight

    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.rootViewController = UITabBarController.alloc.initWithNibName(nil, bundle:nil).tap do |controller|
      controller.viewControllers = tabControllers
    end

    # @window.rootViewController = SuggestedSittersController.alloc.init
    # @window.rootViewController = SitterDetailsController.alloc.init.tap do |c| c.sitter = Sitter.all.first end
    # @window.rootViewController = SettingsController.alloc.initWithForm(SettingsController.form)

    @window.rootViewController = ExpiredController.alloc.init if isExpired
    @window.rootViewController.wantsFullScreenLayout = true

    @window.makeKeyAndVisible

    # login

    true
  end

  def buildDate
    @buildDate ||= dateFromProperty('BuildDate')
  end

  def expirationDate
    @expirationDate ||= dateFromProperty('ExpirationDate')
  end

  def login(&block)
    fb = Firebase.new('https://sevensitters.firebaseio.com/')
    auth = FirebaseSimpleLogin.new(fb)
    puts 'checking auth'
    auth.check do |error, user|
      puts "auth.check -> #{error}, #{user}"
      if error or user
        authDidReturn user, error:error
      else
        permissions = ['email', 'read_friendlists', 'user_hometown', 'user_location', 'user_relationships']
        puts 'logging in'
        auth.login_to_facebook(app_id: 'com.sevensitters.sevensitters', permissions: ['email']) do |error, user|
          puts "login -> #{error}, #{user}"
          authDidReturn user, error:error
        end
      end
    end
  end

  private

  def authDidReturn(user, error:error)
    puts "authDidReturn user=#{user} error=#{error}"
    @user = user
    if error
      puts "showing alert"
      puts error.localizedDescription
      puts error.localizedRecoverySuggestion
      p error.localizedRecoveryOptions
      UIAlertView.alloc.initWithTitle(error.localizedDescription,
        message:error.localizedRecoverySuggestion,
        delegate:nil,
        cancelButtonTitle:'OK',
        otherButtonTitles:error.localizedRecoveryOptions).show
    end
    if user
      UIAlertView.alloc.initWithTitle('User signed in',
        message:user.to_s,
        delegate:nil,
        cancelButtonTitle:'OK',
        otherButtonTitles:nil).show
    end
  end

  def dateFromProperty(propertyName)
    dateString = NSBundle.mainBundle.objectForInfoDictionaryKey(propertyName)
    return nil unless dateString
    dateDateFormatter = NSDateFormatter.alloc.init.setDateFormat("yyyy-MM-dd'T'HH:mm:ssZ")
    dateDateFormatter.dateFromString(dateString)
  end

  def tabControllers
    [
      BookingController.alloc.init,
      SearchSittersController.alloc.init,
      UpdatesController.alloc.init,
      ChatController.alloc.init,
      SettingsController.alloc.initWithForm(SettingsController.form)
    ]
  end

  def isExpired
    return false unless expirationDate
    return expirationDate < NSDate.date
  end

  def initializeTestFlight
    return if Device.simulator?
    # return unless Object.const_defined?(:TestFlight)
    app_token = NSBundle.mainBundle.objectForInfoDictionaryKey('TF_APP_TOKEN')
    # TODO remove call to TestFlight.setDeviceIdentifier before submitting to app store
    TestFlight.setDeviceIdentifier UIDevice.currentDevice.uniqueIdentifier
    TestFlight.takeOff app_token
  end
end

class HelloViewController < UIViewController
  def loadView
    self.view = HelloView.alloc.init
  end
end

class HelloView < UIView
  def drawRect(rect)
    if @moved
      bgcolor = begin
        red, green, blue = rand(100), rand(100), rand(100)
        UIColor.colorWithRed(red/100.0, green:green/100.0, blue:blue/100.0, alpha:1.0)
      end
      text = "ZOMG!"
    else
      bgcolor = UIColor.blackColor
      text = @touches ? "Touched #{@touches} times!" : "Hello RubyMotion!"
    end

    bgcolor.set
    UIBezierPath.bezierPathWithRect(frame).fill

    font = UIFont.systemFontOfSize(24)
    UIColor.whiteColor.set
    text.drawAtPoint(CGPoint.new(10, 20), withFont:font)
  end

  def touchesMoved(touches, withEvent:event)
    @moved = true
    setNeedsDisplay
  end

  def touchesEnded(touches, withEvent:event)
    @moved = false
    @touches ||= 0
    @touches += 1
    setNeedsDisplay
  end
end
