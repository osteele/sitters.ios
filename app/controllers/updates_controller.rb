class UpdatesController < UITableViewController
  def initWithNibName(name, bundle:bundle)
    super
    image = UIImage.imageNamed('tabs/updates.png')
    image = UIImage.imageWithCGImage(image.CGImage, scale:2, orientation:UIImageOrientationUp)
    self.tabBarItem = UITabBarItem.alloc.initWithTitle('Updates', image:image, tag:3)
    self.tabBarItem.badgeValue = Update.unread.length.to_s
    self
  end

  def viewDidLoad
    super
    view.separatorStyle = UITableViewCellSeparatorStyleNone
    @items ||= Update.all
  end

  def viewDidAppear(animated)
    super
    Update.clear
    self.tabBarItem.badgeValue = nil
  end

  def tableView(tableView, heightForHeaderInSection:section); 52; end
  def numberOfSectionsInTableView(tableView); 1; end

  def tableView(tableView, numberOfRowsInSection:section)
    @items.length
  end

  IMAGE_TAG = 1
  TITLE_TAG = 2
  DESCRIPTION_TAG = 3
  TIMESTAMP_TAG = 4

  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    cellIdentifier = self.class.name
    cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
    fontName = "HelveticaNeue"
    unless cell
      cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier:cellIdentifier)
      layout cell.contentView do
        subview UIImageView, tag: IMAGE_TAG, width: 44, height: 44, left: 10, top: 0
        subview UILabel, tag: TITLE_TAG, width: 255, height: 40, left: 65, top: -3, textColor: 0x5988C4.uicolor
        subview UILabel, tag: DESCRIPTION_TAG, width: 255, height: 40, left: 65, top: 14, font: UIFont.fontWithName(fontName, size:14)
        subview UILabel, tag: TIMESTAMP_TAG, width: 200, height: 40, left: 110, top: -3,
          font: UIFont.fontWithName(fontName, size:14), textAlignment: NSTextAlignmentRight
      end
    end

    update = @items[indexPath.row]

    cell.viewWithTag(IMAGE_TAG).image = update.image
    cell.viewWithTag(TITLE_TAG).text = update.contact
    cell.viewWithTag(TITLE_TAG).font = UIFont.fontWithName("HelveticaNeue", size:14)
    cell.viewWithTag(TITLE_TAG).font = UIFont.fontWithName("HelveticaNeue-Bold", size:14) if update.today?
    cell.viewWithTag(DESCRIPTION_TAG).text = update.description
    cell.viewWithTag(TIMESTAMP_TAG).textColor = update.today? ? UIColor.blackColor : UIColor.grayColor
    cell.viewWithTag(TIMESTAMP_TAG).text = update.timestamp
    cell
  end
end
