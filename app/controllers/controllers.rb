class ChatController < UIViewController
  include BW::KVO
  attr_reader :mapView

  def initWithNibName(name, bundle:bundle)
    super
    self.tap do
      self.tabBarItem = UITabBarItem.alloc.initWithTitle('Chat', image:UIImage.imageNamed('tabs/chat'), tag:4)
    end
  end

  def viewWillAppear(animated)
    super
    @locationManager ||= CLLocationManager.alloc.init.tap do |locationManager|
      locationManager.delegate = self
      locationManager.desiredAccuracy = KCLLocationAccuracyKilometer
    end

    @locationManager.startUpdatingLocation
    Scheduler.after 10 do @locationManager.stopUpdatingLocation end
  end

  def locationManager(locationManager, didUpdateLocations:locations)
    location = locations.last
    locationManager.stopUpdatingLocation if 0 < location.horizontalAccuracy and location.horizontalAccuracy < 100
    mapView.setRegion [location.coordinate, [1, 1]], animated:true
    # mapView.centerCoordinate = location.coordinate
  end

  layout do
    @mapView = subview MKMapView.alloc.initWithFrame([[0, 0],[320, 122]]),
      showsUserLocation: true,
      userTrackingMode: MKUserTrackingModeFollow
  end
end

class ExpiredController < UIViewController
  layout do
    textView = subview UITextView, top: 20, width: 320, height: 80,
      editable: false,
      textAlignment: NSTextAlignmentCenter,
      backgroundColor: UIColor.clearColor,
      textColor: UIColor.whiteColor,
      text: "This application has expired."
    textView.font = textView.font.fontWithSize(18)

    button = subview UIButton.buttonWithType(UIButtonTypeSystem), top: 240, width: 320, height: 50, title: 'Tap to update'
    button.font = button.font.fontWithSize(28)

    button.when_tapped do
      UIApplication.sharedApplication.openURL NSURL.URLWithString('https://testflightapp.com/m/apps')
    end
  end
end
