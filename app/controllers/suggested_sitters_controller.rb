class SuggestedSittersController < UITableViewController
  include BW::KVO

  TextColor = '#5988C4'.to_color

  ImageTag = 1
  TitleTag = 2
  DescriptionTag = 3

  attr_accessor :delegate

  def viewDidLoad
    super
    view.backgroundColor = '#F4F3F5'.to_color
    view.separatorStyle = UITableViewCellSeparatorStyleNone
    updateSitterCountText
    observe(Family.instance, :suggested_sitters) do
      @sitters = nil
      view.reloadData
      updateSitterCountText
    end
  end

  def sitters
    @sitters ||= Family.instance.suggested_sitters
  end

  def updateSitterCountText
    return unless @headerLabelView
    @headerLabelView.text = case sitters.length
      when 0 then "None Recommended"
      when 1 then "One Recommended"
      else "#{sitters.length} Recommended"
    end
  end

  def numberOfSectionsInTableView(tableView); 1; end

  ViewHeaderHeight = 52
  TableTextHeaderHeight = 38

  def tableView(tableView, heightForHeaderInSection:section); ViewHeaderHeight + TableTextHeaderHeight; end

  def tableView(tableView, viewForHeaderInSection:section)
    UIView.alloc.initWithFrame([[0, 0], [320, ViewHeaderHeight + TableTextHeaderHeight]]).tap do |view|
      # view.backgroundColor = '#4E7EC2'.to_color # bottom of time selector
      UILabel.alloc.initWithFrame([[0, ViewHeaderHeight], [320, TableTextHeaderHeight]]).tap do |label|
        view.addSubview label
        label.backgroundColor = '#FEFDFF'.to_color
        label.textColor = TextColor
        label.textAlignment = NSTextAlignmentCenter
        @headerLabelView = label
        updateSitterCountText
      end
      # FIXME setting border color on views above doesn't work
      UIView.alloc.initWithFrame([[0, ViewHeaderHeight + TableTextHeaderHeight - 1], [320, 1]]).tap do |border|
        view.addSubview border
        border.backgroundColor = '#CFCED0'.to_color
      end
    end
  end

  def tableView(tableView, numberOfRowsInSection:section); sitters.length; end

  def tableView(tableView, heightForRowAtIndexPath:indexPath); 52; end

  def tableView(tableView, didSelectRowAtIndexPath:indexPath)
    delegate.presentDetailsForSitter sitters[indexPath.row]
  end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    cellIdentifier = self.class.name
    cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
    font = UIFont.fontWithName('HelveticaNeue', size:14)
    unless cell
      cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier:cellIdentifier)
      cell.backgroundColor = UIColor.clearColor
      layout cell.contentView do
        subview UIImageView, tag: ImageTag, width: 47, height: 47, left: 10, top: 5
        subview UILabel, tag: TitleTag, width: 255, height: 40, left: 65, top: -3
        subview UILabel, tag: DescriptionTag, width: 255, height: 40, left: 65, top: 14, font: font
      end
    end

    sitter = sitters[indexPath.row]

    description = NSMutableAttributedString.alloc.initWithString("#{sitter.name} (#{sitter.age} years old)")
    description.addAttribute NSForegroundColorAttributeName, value:TextColor, range:NSMakeRange(0, description.length)
    description.addAttribute NSFontAttributeName, value:font.fontWithSymbolicTraits(UIFontDescriptorTraitBold), range:NSMakeRange(0, sitter.name.length)
    description.addAttribute NSFontAttributeName, value:font.fontWithSize(12), range:NSMakeRange(sitter.name.length, description.length - sitter.name.length)

    cell.viewWithTag(ImageTag).image = sitter.maskedImage
    cell.viewWithTag(TitleTag).attributedText = description
    cell.viewWithTag(DescriptionTag).text = sitter.description
    cell
  end
end
