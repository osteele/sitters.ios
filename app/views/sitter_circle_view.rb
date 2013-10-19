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
  end

  def sitter=(sitter)
    @sitter = sitter
    view.setNeedsDisplay
  end

  def available=(available)
    @available = available
    view.setNeedsDisplay
  end

  def displayLayer(layer)
    view.layer.contents = self.layerImage
  end

  def layerImage
    bounds = view.bounds
    UIGraphicsBeginImageContextWithOptions bounds.size, false, 0

    sitterNameFont = UIFont.fontWithName('Helvetica-Bold', size:9)
    sitterNameColor = sitter && !available ? 0xaaaaaa.uicolor : UIColor.blackColor
    numberLabelFont = UIFont.fontWithName('Helvetica', size:13)
    numberLabelColor = sitter ? UIColor.blackColor : 0xaaaaaa.uicolor
    frameColor = 0xcccccc.uicolor.CGColor
    outerRingWidth = 10
    labelCircleRadius = 11
    sitterNameRadius = 36

    cx = cy = bounds.size.width / 2
    outerRadius = bounds.size.width / 2 - 1
    innerRadius = outerRadius - 10

    context = UIGraphicsGetCurrentContext()
    CGContextSaveGState context
    CGContextTranslateCTM context, 0, bounds.size.height
    CGContextScaleCTM context, 1, -1

    # Outer circle: fill and frame
    CGContextAddArc context, cx, cy, outerRadius, 0, 2 * Math::PI, 0
    CGContextSetFillColorWithColor context, UIColor.whiteColor.CGColor
    CGContextFillPath context

    CGContextAddArc context, cx, cy, outerRadius, 0, 2 * Math::PI, 0
    CGContextSetStrokeColorWithColor context, frameColor
    CGContextStrokePath context

    # Inner circle: fill and frame
    CGContextAddArc context, cx, cy, innerRadius, 0, 2 * Math::PI, 0
    CGContextSetFillColorWithColor context, 0xA6A6A6.uicolor.CGColor
    CGContextFillPath context

    CGContextAddArc context, cx, cy, innerRadius, 0, 2 * Math::PI, 0
    CGContextSetStrokeColorWithColor context, frameColor
    CGContextStrokePath context

    imageRect = CGRectMake(outerRingWidth, outerRingWidth, bounds.size.width - 2 * outerRingWidth, bounds.size.height - 2 * outerRingWidth)
    CGContextDrawImage context, imageRect, sitterImage
    if sitter and not available
      CGContextAddArc context, cx, cy, innerRadius, 0, 2 * Math::PI, 0
      CGContextSetFillColorWithColor context, BubbleWrap.rgba_color(255, 255, 255, 0.7).CGColor
      CGContextFillPath context
    end

    CGContextAddArc context, cx, labelCircleRadius + 3, labelCircleRadius, 0, 2 * Math::PI, 0
    CGContextSetFillColorWithColor context, 0xaaaaaa.uicolor.CGColor # UIColor.grayColor.CGColor
    CGContextFillPath context

    CGContextAddArc context, cx, labelCircleRadius + 2, labelCircleRadius, 0, 2 * Math::PI, 0
    CGContextSetFillColorWithColor context, UIColor.whiteColor.CGColor
    CGContextFillPath context

    # Sitter name
    if sitter
      textAttributes = { NSFontAttributeName => sitterNameFont, NSForegroundColorAttributeName => sitterNameColor }
      sitterNameAS = NSAttributedString.alloc.initWithString(sitter.firstName.upcase, attributes:textAttributes)
      GraphicsUtils.showStringOnArc context, sitterNameAS, cx, cy, sitterNameRadius
    end

    CGContextRestoreGState context

    # CGContextSetFillColorWithColor context, UIColor.blackColor.CGColor
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
