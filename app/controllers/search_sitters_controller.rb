class SearchSittersController < UITableViewController
  def initWithNibName(name, bundle:bundle)
    super
    self.tap do
      self.tabBarItem = UITabBarItem.alloc.initWithTabBarSystemItem(UITabBarSystemItemSearch, tag:2)
      self.edgesForExtendedLayout = UIRectEdgeNone
    end
  end

  def prefersStatusBarHidden
    return true
  end

  def data
    @searchResults ||= @sitters = Sitter.all.select(&:lastName).sort_by(&:lastName)
  end

  def viewDidLoad
    super
    view.backgroundColor = '#f9f9f9'.to_color
    view.separatorStyle = UITableViewCellSeparatorStyleNone
  end

  def viewDidAppear(animated)
    super
    App.shared.setStatusBarHidden true
  end

  def viewDidDisappear(animated)
    super
    App.shared.setStatusBarHidden false
  end

  layout do
    search_bar = subview UISearchBar, frame: [0, 20, 320, 44], delegate: self
    view.tableHeaderView = search_bar
  end

  def searchBar(search_bar, textDidChange:searchText)
    searchText = searchText.upcase
    @searchResults = @sitters.select { |sitter| sitter.name.upcase.include? searchText.upcase }
    view.reloadData
  end

  def numberOfSectionsInTableView(tableView); 1; end

  def tableView(tableView, heightForRowAtIndexPath:indexPath); 52; end

  def tableView(tableView, didSelectRowAtIndexPath:indexPath)
    self.view.endEditing true
  end

  def tableView(tableView, numberOfRowsInSection:section)
    data.length
  end

  IMAGE_TAG = 1
  TITLE_TAG = 2
  DESCRIPTION_TAG = 3

  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    plainFont = UIFont.fontWithName("HelveticaNeue", size:14)
    boldFont = plainFont.fontWithSymbolicTraits(UIFontDescriptorTraitBold)

    cellIdentifier = self.class.name
    cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)

    cell ||= UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier:cellIdentifier).tap do |cell|
      cell.backgroundColor = UIColor.clearColor
      layout cell.contentView do
        image = subview UIImageView, tag: IMAGE_TAG, width: 47, height: 47, left: 10, top: 5
        image.layer.cornerRadius = image.width / 2
        image.layer.masksToBounds = true
        subview UILabel, tag: TITLE_TAG, width: 255, height: 40, left: 65, top: -3
        subview UILabel, tag: DESCRIPTION_TAG, width: 255, height: 40, left: 65, top: 14, font: plainFont
      end
    end
    sitter = data[indexPath.row]

    cell.textLabel.origin = [150, cell.textLabel.origin.y]
    cell.detailTextLabel.origin = [150, cell.detailTextLabel.origin.y]

    description = NSMutableAttributedString.alloc.initWithString("#{sitter.name} (#{sitter.age} years old)")
    description.addAttribute NSForegroundColorAttributeName, value:'#5988C4'.to_color, range:NSMakeRange(0, description.length)
    description.addAttribute NSFontAttributeName, value:boldFont, range:NSMakeRange(0, sitter.name.length)
    description.addAttribute NSFontAttributeName, value:plainFont.fontWithSize(12), range:NSMakeRange(sitter.name.length, description.length - sitter.name.length)

    cell.viewWithTag(IMAGE_TAG).image = sitter.maskedImage
    cell.viewWithTag(TITLE_TAG).attributedText = description
    cell.viewWithTag(DESCRIPTION_TAG).text = sitter.description
    cell
  end
end
