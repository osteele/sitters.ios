class SearchController < UITableViewController
  def initWithNibName(name, bundle:bundle)
    super
    self.tap do
      self.tabBarItem = UITabBarItem.alloc.initWithTabBarSystemItem(UITabBarSystemItemSearch, tag:2)
    end
  end

  def viewDidLoad
    super
    @sitters = Sitter.suggested
  end

  layout do
    search_bar = subview UISearchBar, frame: [0, 20, 320, 44], delegate: self
    view.tableHeaderView = search_bar
  end

  def searchBar(search_bar, textDidChange:searchText)
    searchText = searchText.upcase
    @sitters = Sitter.all.select { |sitter| sitter.name.upcase.include? searchText.upcase }
    view.reloadData
  end

  def numberOfSectionsInTableView(tableView)
    1
  end

  def tableView(tableView, numberOfRowsInSection:section)
    @sitters ||= Sitter.suggested
    @sitters.length
  end

  IMAGE_TAG = 1
  DATE_TAG = 2

  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    cellIdentifier = self.class.name
    cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
    unless cell
      cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier:cellIdentifier)
      layout cell.contentView do
        subview UIImageView, :image, tag: IMAGE_TAG, width: 40, height: 40
        # subview UILabel, :image, tag: DATE_TAG, width: 100, height: 40, left: 260, backgroundColor: UIColor.greenColor, text:'4:12 PM'
      end
    end
    sitter = @sitters[indexPath.row]

    cell.textLabel.origin = [150, cell.textLabel.origin.y]
    cell.detailTextLabel.origin = [150, cell.detailTextLabel.origin.y]

    cell.textLabel.text = "#{sitter.name} (#{sitter.age} years old)"
    cell.detailTextLabel.text = sitter.description
    cell.viewWithTag(IMAGE_TAG).image = sitter.image
    # cell.viewWithTag(DATE_TAG).text = 'today'
    cell
  end
end
