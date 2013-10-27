class SuggestedSittersController < UITableViewController
  include BW::KVO

  ImageTag = 1
  TitleTag = 2
  DescriptionTag = 3

  attr_accessor :delegate

  def viewDidLoad
    super
    view.separatorStyle = UITableViewCellSeparatorStyleNone
    observe(Family.instance, :suggested_sitters) do @sitters = nil; view.reloadData end
  end

  def sitters
    @sitters ||= Family.instance.suggested_sitters
  end

  def numberOfSectionsInTableView(tableView); 1; end

  def tableView(tableView, heightForHeaderInSection:section); 52; end
  def tableView(tableView, heightForRowAtIndexPath:indexPath); 52; end
  def tableView(tableView, numberOfRowsInSection:section); sitters.length; end

  def tableView(tableView, didSelectRowAtIndexPath:indexPath)
    delegate.presentDetailsForSitter sitters[indexPath.row]
  end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    cellIdentifier = self.class.name
    cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
    fontName = "HelveticaNeue"
    unless cell
      cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier:cellIdentifier)
      layout cell.contentView do
        subview UIImageView, tag: ImageTag, width: 47, height: 47, left: 10, top: 5
        subview UILabel, tag: TitleTag, width: 255, height: 40, left: 65, top: -3
        subview UILabel, tag: DescriptionTag, width: 255, height: 40, left: 65, top: 14, font: UIFont.fontWithName(fontName, size:14)
      end
    end

    sitter = sitters[indexPath.row]

    description = NSMutableAttributedString.alloc.initWithString("#{sitter.name} (#{sitter.age} years old)")
    description.addAttribute NSForegroundColorAttributeName, value:'#5988C4'.to_color, range:NSMakeRange(0, description.length)
    description.addAttribute NSFontAttributeName, value:UIFont.fontWithName(fontName + '-Bold', size:14), range:NSMakeRange(0, sitter.name.length)
    description.addAttribute NSFontAttributeName, value:UIFont.fontWithName(fontName, size:12), range:NSMakeRange(sitter.name.length, description.length - sitter.name.length)

    cell.viewWithTag(ImageTag).image = sitter.maskedImage
    cell.viewWithTag(TitleTag).attributedText = description
    cell.viewWithTag(DescriptionTag).text = sitter.description
    cell
  end
end
