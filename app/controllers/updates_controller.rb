class UpdatesController < UITableViewController
  def initWithNibName(name, bundle:bundle)
    super
    self.tap do
      self.tabBarItem = UITabBarItem.alloc.initWithTitle('Updates', image:UIImage.imageNamed('updates.png'), tag:3)
    end
  end

  # layout do
  #   search_bar = subview UISearchBar, frame: [0, 20, 320, 44], delegate: self
  #   view.tableHeaderView = search_bar
  # end

  def numberOfSectionsInTableView(tableView)
    1
  end

  def tableView(tableView, numberOfRowsInSection:section)
    @sitters ||= Update.all
    @sitters.length
  end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    cellIdentifier = self.class.name
    cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) ||
      UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier:cellIdentifier)
    update = Update.all[indexPath.row]
    cell.textLabel.text = update.contact
    cell.detailTextLabel.text = update.description
    cell
  end
end
