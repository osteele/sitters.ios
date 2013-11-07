class ChatController < UIViewController
  include BW::KVO
  attr_reader :mapView

  def initWithNibName(name, bundle:bundle)
    super
    self.tabBarItem = UITabBarItem.alloc.initWithTitle('Chat', image:UIImage.imageNamed('tabs/chat'), tag:4)
    self
  end

  def viewWillAppear(animated)
    super
    # set this here instead instead of initialization so we need permission until user sees the map
    mapView.showsUserLocation = true
  end

  def mapView(mapView, didUpdateUserLocation:userLocation)
    return unless mapView.userLocation.location
    coordinate = mapView.userLocation.coordinate
    mapView.setRegion [coordinate, [0.2, 0.2]], animated:true
  end

  layout do
    view.backgroundColor = '#f9f9f9'.to_color

    @mapView = subview MKMapView.alloc.initWithFrame([[0, 20],[320, 122]]),
      delegate: self,
      userTrackingMode: MKUserTrackingModeFollow

    subview UIImageView,
      top: 20 + 122,
      size: [320, 325],
      image: UIImage.imageNamed('images/chat-placeholder')
  end
end
