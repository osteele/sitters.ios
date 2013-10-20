class SitterCircleController
  attr_accessor :view
  attr_accessor :sitter
  attr_accessor :labelString
  attr_accessor :available

  def initWithSitter(sitter, labelString:label)
    # initWithNibName(nil, bundle:nil)
    @view = UIView.alloc.initWithFrame([[0,0],[90,90]])

    @sitter = sitter
    @labelString = label
    @available = false

    self
  end

  def viewDidLoad
    @loaded = true

    keynoteShadowRadiusRatio = 0.25
    keynoteShadowOffsetRatio = 0.5

    view.layer.delegate = self
    view.layer.bounds = view.bounds
    view.layer.setNeedsDisplay

    @imageLayer = CALayer.layer
    imageLayer.contents = sitterImage
    view.layer.addSublayer imageLayer

    @ringLayer = CALayer.layer
    ringLayer.shadowColor = UIColor.blackColor.CGColor
    ringLayer.shadowOffset = [0, 1 * keynoteShadowOffsetRatio]
    ringLayer.shadowOpacity = 0.5
    ringLayer.shadowRadius = 3 * keynoteShadowRadiusRatio
    view.layer.addSublayer ringLayer

    @numberLabelLayer = CALayer.layer
    numberLabelLayer.shadowColor = UIColor.blackColor.CGColor
    numberLabelLayer.shadowOffset = [0, -3 * keynoteShadowOffsetRatio]
    numberLabelLayer.shadowRadius = 2 * keynoteShadowRadiusRatio
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

    sitterImageIngress = 0.09
    imageLayer.bounds = view.bounds
    imageLayer.position = center
    imageLayer.contentsRect = [[-sitterImageIngress, -sitterImageIngress], [1 + 2 * sitterImageIngress, 1 + 2 * sitterImageIngress]]
    # imageLayer.contentsGravity = KCAGravityCenter

    ringLayer.bounds = view.bounds
    ringLayer.position = center
    # ringLayer.contentsGravity = KCAGravityCenter

    numberLabelLayer.bounds = view.bounds
    numberLabelLayer.position = center
    # numberLabelLayer.contentsGravity = KCAGravityCenter
  end

  def updateLayerContents
    return unless @loaded
    ringLayer.contents = ringLayerImage
    numberLabelLayer.contents = numberLayerImage
  end

  private

  attr_reader :imageLayer
  attr_reader :ringLayer
  attr_reader :numberLabelLayer

  def ringLayerImage
    bounds = view.bounds
    UIGraphicsBeginImageContextWithOptions bounds.size, false, 0

    sitterNameFont = UIFont.fontWithName('Helvetica-Bold', size:9)
    sitterNameColor = sitter && !available ? 0xaaaaaa.uicolor : UIColor.blackColor
    outerRingWidth = 10
    sitterNameRadius = 36

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
      sitterNameAS = NSAttributedString.alloc.initWithString(sitter.firstName.upcase, attributes:textAttributes)
      GraphicsUtils.showStringOnArc context, sitterNameAS, cx, cy, sitterNameRadius
    end

    CGContextRestoreGState context

    layerImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return layerImage.CGImage
  end

  def numberLayerImage
    bounds = view.bounds
    cx = cy = bounds.size.width / 2

    UIGraphicsBeginImageContextWithOptions bounds.size, false, 0
    context = UIGraphicsGetCurrentContext()

    numberLabelFont = UIFont.fontWithName('Helvetica', size:13)
    numberLabelColor = sitter ? UIColor.blackColor : 0xaaaaaa.uicolor
    labelCircleRadius = 13

    CGContextAddArc context, cx, bounds.size.height - labelCircleRadius - 2, labelCircleRadius, 0, 2 * Math::PI, 0
    CGContextSetFillColorWithColor context, UIColor.whiteColor.CGColor
    CGContextFillPath context

    labelRect = CGRectMake(0, bounds.size.height - 2 * labelCircleRadius + 2, bounds.size.width, 2 * labelCircleRadius)
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
    SitterCircleController.sitterImage(sitter)
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
