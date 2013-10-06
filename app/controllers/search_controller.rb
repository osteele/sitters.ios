class SearchController < UITableViewController
  def initWithNibName(name, bundle:bundle)
    super
    self.tap do
      self.tabBarItem = UITabBarItem.alloc.initWithTabBarSystemItem(UITabBarSystemItemSearch, tag:2)
    end
  end

  def viewDidLoad
    super
    @sitters = Sitter.all
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
    @sitters ||= Sitter.all
    @sitters.length
  end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    cellIdentifier = self.class.name
    cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) ||
      UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier:cellIdentifier)
    sitter = @sitters[indexPath.row]
    cell.textLabel.text = sitter.name
    cell.detailTextLabel.text = sitter.description
    cell
  end
end
