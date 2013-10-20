class SitterCircleController < UIViewController
  attr_accessor :sitter
  attr_accessor :labelText
  attr_accessor :available

  def initWithSitter(sitter, labelString:label)
    initWithNibName(nil, bundle:nil)
    @sitter = sitter
    @labelText = label
    @available = false
    self
  end

  def viewDidLoad
    super
    view.layer.delegate = self
    view.layer.bounds = view.bounds
    view.layer.setNeedsDisplay

    imageLayer = @imageLayer = CALayer.layer
    imageLayer.contents = sitterImage
    view.layer.addSublayer imageLayer

    ringLayer = @ringLayer = CALayer.layer
    ringLayer.shadowColor = UIColor.blackColor.CGColor
    ringLayer.shadowOffset = [0, 0.5]
    ringLayer.shadowOpacity = 0.5
    ringLayer.shadowRadius = 1.5
    view.layer.addSublayer ringLayer

    numberLabelLayer = @numberLabelLayer = CALayer.layer
    numberLabelLayer.shadowColor = UIColor.blackColor.CGColor
    numberLabelLayer.shadowOffset = [0, -1.5]
    numberLabelLayer.shadowRadius = 1
    numberLabelLayer.shadowOpacity = 0.20
    view.layer.addSublayer numberLabelLayer
  end

  def sitter=(sitter)
    return if @sitter = sitter
    @sitter = sitter
    @imageLayer.contents = sitterImage
    view.setNeedsDisplay
  end

  def available=(available)
    return if @available = available
    @available = available
    view.setNeedsDisplay
    displayLayer(nil)
  end

  def layoutSublayersOfLayer(layer)
    @imageLayer.bounds = view.bounds
    @imageLayer.position = [view.width / 2, view.height / 2]

    @ringLayer.bounds = view.bounds
    @ringLayer.position = [view.width / 2, view.height / 2]

    @numberLabelLayer.bounds = view.bounds
    @numberLabelLayer.position = [view.width / 2, view.height / 2]
  end

  def displayLayer(layer)
    @ringLayer.contents = self.ringLayerImage
    @numberLabelLayer.contents = self.numberLayerImage
  end

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
    labelCircleRadius = 11

    CGContextAddArc context, cx, bounds.size.height - labelCircleRadius - 2, labelCircleRadius, 0, 2 * Math::PI, 0
    CGContextSetFillColorWithColor context, UIColor.whiteColor.CGColor
    CGContextFillPath context

    labelRect = CGRectMake(0, bounds.size.height - 2 * labelCircleRadius + 2, bounds.size.width, 2 * labelCircleRadius)
    labelText.drawInRect labelRect, withAttributes: {
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
      CGImageCreateWithMask(placeholder.CGImage, self.maskImage)
    end
  end

  def self.sitterImage(sitter)
    return self.placeholderImage unless sitter and sitter.image
    CGImageCreateWithMask(sitter.image.CGImage, self.maskImage)
  end

  private

  def self.maskImage
    @maskImage ||= begin
      width = 160
      graySpace = CGColorSpaceCreateDeviceGray()
      context = CGBitmapContextCreate(nil, width, width, 8, 0, graySpace, KCGImageAlphaNone)

      radius = cx = cy = width / 2
      radius -= 4
      CGContextAddArc context, cx, cy, radius, 0, 2 * Math::PI, 0
      CGContextSetFillColorWithColor context, UIColor.whiteColor.CGColor
      CGContextFillPath context

      # radius = 11 * 160 / 90
      # cy = radius - 2
      # CGContextAddArc context, cx, cy, radius, 0, 2 * Math::PI, 0
      # CGContextSetFillColorWithColor context, UIColor.blackColor.CGColor
      # CGContextFillPath context

      cgMask = CGBitmapContextCreateImage(context)
    end
  end
end
