class SearchController < UITableViewController
  def initWithNibName(name, bundle:bundle)
    super
    self.tap do
      self.tabBarItem = UITabBarItem.alloc.initWithTitle('Search', image:UIImage.imageNamed('search.png'), tag:2)
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
    @sitters = Sitter.all.select do |sitter| sitter.name.upcase.include? searchText end
    view.reloadData
  end

  def numberOfSectionsInTableView(tableView)
    1
  end

  def tableView(tableView, numberOfRowsInSection:section)
    Sitter.all.length
    @sitters ||= Sitter.all
    @sitters.length
  end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    cellIdentifier = self.class.name
    cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) ||
      UITableViewCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier:cellIdentifier)
    sitter = Sitter.all[indexPath.row]
    cell.textLabel.text = sitter.name
    cell
  end
end
