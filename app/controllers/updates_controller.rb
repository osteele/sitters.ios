class UpdatesController < UITableViewController
  ImageTag = 1
  TitleTag = 2
  DescriptionTag = 3
  TimestampTag = 4

  def initWithNibName(name, bundle:bundle)
    super
    image = UIImage.imageNamed('tabs/updates')
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

  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    cellIdentifier = self.class.name
    cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)

    fontName = 'Helvetica'
    fontSize = 14
    plainFont = UIFont.fontWithName(fontName, size:fontSize)
    boldFont = UIFont.fontWithName("#{fontName}-Bold", size:fontSize)

    unless cell
      cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier:cellIdentifier)
      layout cell.contentView do
        subview UIImageView, tag: ImageTag, width: 44, height: 44, left: 10, top: 0
        subview UILabel, tag: TitleTag, width: 255, height: 40, left: 65, top: -3, textColor: '#5988C4'.to_color
        subview UILabel, tag: DescriptionTag, width: 255, height: 40, left: 65, top: 14, font: plainFont
        subview UILabel, tag: TimestampTag, width: 200, height: 40, left: 110, top: -3,
          font: plainFont, textAlignment: NSTextAlignmentRight
      end
    end

    update = @items[indexPath.row]

    cell.viewWithTag(ImageTag).image = update.image
    cell.viewWithTag(TitleTag).text = update.contact
    cell.viewWithTag(TitleTag).font = plainFont
    cell.viewWithTag(TitleTag).font = boldFont if update.today?
    cell.viewWithTag(DescriptionTag).text = update.description
    cell.viewWithTag(TimestampTag).textColor = update.today? ? UIColor.blackColor : UIColor.grayColor
    cell.viewWithTag(TimestampTag).text = update.timestamp
    cell
  end
end
