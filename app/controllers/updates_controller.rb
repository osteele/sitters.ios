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
    view.backgroundColor = '#f9f9f9'.to_color
    view.separatorStyle = UITableViewCellSeparatorStyleNone
    @items ||= Update.all
  end

  def viewDidAppear(animated)
    super
    Update.clear
    self.tabBarItem.badgeValue = nil
  end

  def numberOfSectionsInTableView(tableView); 1; end

  def tableView(tableView, heightForHeaderInSection:section); 62; end

  def tableView(tableView, viewForHeaderInSection:section)
    UIView.alloc.initWithFrame([[-1, -1], [320 + 2, 62]]).tap do |view|
      view.layer.borderWidth = 1
      view.layer.borderColor = '#bbbabc'.to_color.CGColor
      UILabel.alloc.initWithFrame([[0, 30], [320, 20]]).tap do |label|
        view.addSubview label
        label.text = 'Updates'
        label.textAlignment = NSTextAlignmentCenter
      end
    end
  end

  def tableView(tableView, numberOfRowsInSection:section)
    @items.length
  end

  def tableView(tableView, heightForRowAtIndexPath:indexPath); 51; end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    plainFont = UIFont.fontWithName('Helvetica Neue', size:14)
    boldFont = plainFont.fontWithSymbolicTraits(UIFontDescriptorTraitBold)

    cellIdentifier = self.class.name
    cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)

    cell ||= UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier:cellIdentifier).tap do |cell|
      cell.backgroundColor = '#f4f2f4'.to_color
      layout cell.contentView do
        image = subview UIImageView, tag: ImageTag, width: 44, height: 44, left: 10, top: 7
        image.layer.cornerRadius = image.width / 2
        image.layer.masksToBounds = true
        subview UILabel, tag: TitleTag, width: 255, height: 40, left: 65, top: 2, textColor: '#5988C4'.to_color
        subview UILabel, tag: DescriptionTag, width: 255, height: 40, left: 65, top: 20,
          font: plainFont.fontWithSize(12)
        subview UILabel, tag: TimestampTag, width: 200, height: 40, left: 110, top: 3,
          font: plainFont.fontWithSize(11),
          textAlignment: NSTextAlignmentRight
      end
    end

    item = @items[indexPath.row]

    cell.viewWithTag(ImageTag).image = item.image
    cell.viewWithTag(TitleTag).font = item.today? ? boldFont : plainFont
    cell.viewWithTag(TitleTag).text = item.contact
    cell.viewWithTag(DescriptionTag).text = item.description
    cell.viewWithTag(TimestampTag).textColor = item.today? ? UIColor.blackColor : UIColor.grayColor
    cell.viewWithTag(TimestampTag).text = item.timestamp
    cell
  end
end
