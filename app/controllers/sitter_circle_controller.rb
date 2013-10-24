# This class controls a view, but it is not a UIViewController.
#
# This is because it semantically controls the view, but does not control a significant
# rectangular subset of the superview or implement its own response to view, transition, containment, layout, and rotation
# events as views in the view containment hierarchy are assumed to do -- it was more work to splice this in as a subview
# controller than to let it manage a subview in a different controller's views.
class SitterCircleController
  attr_accessor :view
  attr_accessor :sitter
  attr_accessor :labelString
  attr_accessor :available

  ViewSize = 90

  def initWithSitter(sitter, labelString:label)
    @sitter = sitter
    @labelString = label
    @available = false

    @view = UIView.alloc.initWithFrame([[0,0],[ViewSize,ViewSize]])

    self
  end

  # The owner must call this
  def viewDidLoad
    @loaded = true

    view.layer.delegate = self
    view.layer.bounds = view.bounds
    view.layer.setNeedsDisplay

    @imageLayer = CALayer.layer
    imageLayer.contents = sitterImage
    view.layer.addSublayer imageLayer

    @ringLayer = CALayer.layer
    ringLayer.shadowColor = UIColor.blackColor.CGColor
    ringLayer.shadowOffset = [0, 1 * KeynoteShadowOffsetRatio]
    # ringLayer.shadowOpacity = 0.K
    ringLayer.shadowRadius = 3 * KeynoteShadowRadiusRatio
    view.layer.addSublayer ringLayer

    @numberLabelLayer = CALayer.layer
    numberLabelLayer.shadowColor = UIColor.blackColor.CGColor
    numberLabelLayer.shadowOffset = [0, -3 * KeynoteShadowOffsetRatio]
    numberLabelLayer.shadowRadius = 2 * KeynoteShadowRadiusRatio
    numberLabelLayer.shadowOpacity = 0.20
    view.layer.addSublayer numberLabelLayer

    updateLayerContents
  end

  def sitter=(sitter)
    return if @sitter == sitter
    @sitter = sitter
    imageLayer.contents = sitterImage
    view.setNeedsDisplay
  end

  def available=(available)
    return if @available == available
    @available = available
    updateLayerContents
    view.setNeedsDisplay
  end

  def layoutSublayersOfLayer(layer)
    center = [view.width / 2, view.height / 2]

    imageIngress = 0.09
    imageIngress = 0.15 if not sitter
    imageLayer.bounds = view.bounds
    imageLayer.position = center
    imageLayer.contentsRect = [[-imageIngress, -imageIngress], [1 + 2 * imageIngress, 1 + 2 * imageIngress]]
    imageLayer.backgroundColor = sitter ? UIColor.clearColor : 0xA5A5A5.uicolor.CGColor
    imageLayer.cornerRadius = view.width / 2
    # imageLayer.masksToBounds = true

    ringLayer.bounds = view.bounds
    ringLayer.position = center

    numberLabelLayer.bounds = view.bounds
    numberLabelLayer.position = center
    # numberLabelLayer.contentsGravity = KCAGravityCenter
  end

  def updateLayerContents
    return unless @loaded
    ringLayer.contents = createRingLayerImage
    numberLabelLayer.contents = createNumberLayerImage
    ringLayer.shadowOpacity = sitter ? 0.5 : 0
    ringLayer.shadowRadius = sitter ? 3 * KeynoteShadowRadiusRatio : 0
  end

  private

  attr_reader :imageLayer
  attr_reader :ringLayer
  attr_reader :numberLabelLayer

  def createRingLayerImage
    bounds = view.bounds
    UIGraphicsBeginImageContextWithOptions bounds.size, false, 0

    sitterNameFont = UIFont.fontWithName('Helvetica-Bold', size:8)
    sitterNameColor = available ? UIColor.blackColor : 0xaaaaaa.uicolor
    outerRingWidth = 11
    sitterNameRadius = 39

    cx = cy = bounds.size.width / 2
    outerRadius = bounds.size.width / 2 - 1
    innerRadius = outerRadius - 10

    context = UIGraphicsGetCurrentContext()
    CGContextSaveGState context
    CGContextTranslateCTM context, 0, bounds.size.height
    CGContextScaleCTM context, 1, -1

    # Outer circle
    CGContextAddArc context, cx, cy, outerRadius, 0, 2 * Math::PI, 0
    CGContextSetFillColorWithColor context, UIColor.whiteColor.CGColor
    CGContextFillPath context

    # Inner circle
    CGContextAddArc context, cx, cy, innerRadius, 0, 2 * Math::PI, 0
    # CGContextSetFillColorWithColor context, 0xA6A6A6.uicolor.CGColor
    CGContextSetBlendMode context, KCGBlendModeClear
    CGContextFillPath context
    CGContextSetBlendMode context, KCGBlendModeNormal

    if sitter and not available
      CGContextAddArc context, cx, cy, innerRadius, 0, 2 * Math::PI, 0
      CGContextSetFillColorWithColor context, BubbleWrap.rgba_color(255, 255, 255, 0.7).CGColor
      CGContextFillPath context
    end

    # Sitter name
    if sitter
      textAttributes = { NSFontAttributeName => sitterNameFont, NSForegroundColorAttributeName => sitterNameColor }
      sitterName = NSAttributedString.alloc.initWithString(sitter.firstName.upcase, attributes:textAttributes)
      sitterName.drawOnArc cx, cy, sitterNameRadius
    end

    CGContextRestoreGState context
    layerImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return layerImage.CGImage
  end

  def createNumberLayerImage
    bounds = view.bounds
    cx = cy = bounds.size.width / 2

    UIGraphicsBeginImageContextWithOptions bounds.size, false, 0
    context = UIGraphicsGetCurrentContext()

    numberLabelFont = UIFont.fontWithName('Helvetica', size:13)
    numberLabelColor = sitter ? UIColor.blackColor : 0xaaaaaa.uicolor
    labelCircleRadius = 12
    labelNameDeltaY = 4

    CGContextAddArc context, cx, bounds.size.height - labelCircleRadius - 1, labelCircleRadius, 0, 2 * Math::PI, 0
    CGContextSetFillColorWithColor context, UIColor.whiteColor.CGColor
    CGContextFillPath context

    labelRect = CGRectMake(0, bounds.size.height - 2 * labelCircleRadius + labelNameDeltaY, bounds.size.width, 2 * labelCircleRadius)
    labelString.drawInRect labelRect, withAttributes: {
      NSFontAttributeName => numberLabelFont,
      NSForegroundColorAttributeName => numberLabelColor,
      NSParagraphStyleAttributeName => NSMutableParagraphStyle.alloc.init.tap { |s| s.alignment = NSTextAlignmentCenter }
    }

    layerImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return layerImage.CGImage
  end

  def sitterImage
    self.class.sitterImage(sitter)
  end

  def self.placeholderImage
    @placeholderImage ||= begin
      placeholder = UIImage.imageNamed('images/sitter-placeholder')
      CGImageCreateWithMask(placeholder.CGImage, self.sitterCircleMaskImage)
    end
  end

  public

  def self.sitterImage(sitter)
    return self.placeholderImage unless sitter and sitter.image
    CGImageCreateWithMask(sitter.image.CGImage, self.sitterCircleMaskImage)
  end

  private

  def self.sitterCircleMaskImage
    width = 160

    @sitterCircleMaskImages ||= begin
      graySpace = CGColorSpaceCreateDeviceGray()
      context = CGBitmapContextCreate(nil, width, width, 8, 0, graySpace, KCGImageAlphaNone)

      radius = cx = cy = width / 2
      radius -= 4
      CGContextAddArc context, cx, cy, radius, 0, 2 * Math::PI, 0
      CGContextSetFillColorWithColor context, UIColor.whiteColor.CGColor
      CGContextFillPath context

      cgMask = CGBitmapContextCreateImage(context)
    end
  end
end
