class SitterCircleView < UIView
  attr_accessor :sitter
  attr_accessor :labelText

  def self.new
    view = alloc.initWithFrame(CGRectZero)
    view
  end

  def drawRect(rect)
    if sitter
      layer.shadowOffset = [0, 0.5]
      layer.shadowOpacity = 0.25
      layer.shadowRadius = 0.5
    end

    bounds = CGRectMake(0, 0, self.size.width, self.size.height)

    context = UIGraphicsGetCurrentContext()
      CGContextSaveGState context
    CGContextTranslateCTM context, 0, bounds.size.height
    CGContextScaleCTM context, 1, -1

    # Outer circle: fill and frame
    radius = cx = cy = bounds.size.width / 2
    radius -= 1
    CGContextAddArc context, cx, cy, radius, 0, 2 * Math::PI, 0
    CGContextSetFillColorWithColor context, UIColor.whiteColor.CGColor
    CGContextFillPath context

    CGContextAddArc context, cx, cy, radius, 0, 2 * Math::PI, 0
    CGContextSetStrokeColorWithColor context, UIColor.grayColor.CGColor
    CGContextStrokePath context

    # Inner circle: fill and frame
    radius -= 10
    CGContextAddArc context, cx, cy, radius, 0, 2 * Math::PI, 0
    CGContextSetFillColorWithColor context, 0xA6A6A6.uicolor.CGColor
    CGContextFillPath context

    CGContextAddArc context, cx, cy, radius, 0, 2 * Math::PI, 0
    CGContextSetStrokeColorWithColor context, UIColor.grayColor.CGColor
    CGContextStrokePath context

    ringWidth = 10
    imageRect = CGRectMake(ringWidth, ringWidth, bounds.size.width - 2 * ringWidth, bounds.size.height - 2 * ringWidth)
    CGContextDrawImage context, imageRect, sitterImage

    labelCircleRadius = 11
    CGContextAddArc context, cx, labelCircleRadius + 3, labelCircleRadius, 0, 2 * Math::PI, 0
    CGContextSetFillColorWithColor context, UIColor.grayColor.CGColor
    CGContextFillPath context

    CGContextAddArc context, cx, labelCircleRadius + 2, labelCircleRadius, 0, 2 * Math::PI, 0
    CGContextSetFillColorWithColor context, UIColor.whiteColor.CGColor
    CGContextFillPath context

    # Sitter name
    if NSUserDefaults.standardUserDefaults[:arc_text] and sitter
      radius = 36
      font = UIFont.fontWithName('HelveticaNeue', size:10)
      CGContextSelectFont context, font.fontName, font.pointSize, KCGEncodingMacRoman
      CGContextSetFillColorWithColor context, UIColor.blackColor.CGColor
      textAttributes = { NSFontAttributeName => font }
      sitterName = sitter.firstName.upcase
      sitterNameAS = NSAttributedString.alloc.initWithString(sitterName, attributes:textAttributes)
      GraphicsUtils.showStringOnArc context, sitterNameAS, sitterName, cx, cy, radius
    end

    CGContextRestoreGState context

    # CGContextSetFillColorWithColor context, UIColor.blackColor.CGColor
    labelRect = CGRectMake(0, self.height - 2 * labelCircleRadius, self.width, 2 * labelCircleRadius)
    labelText.drawInRect labelRect, withAttributes: {
      NSFontAttributeName => UIFont.fontWithName('HelveticaNeue', size:14),
      NSForegroundColorAttributeName => UIColor.blackColor,
      NSParagraphStyleAttributeName => NSMutableParagraphStyle.alloc.init.tap { |s| s.alignment = NSTextAlignmentCenter }
    }
  end

  def sitterImage
    SitterCircleView.sitterImage(sitter)
  end

  def self.placeholderImage
    @placeholderImage ||= begin
      placeholder = UIImage.imageNamed('images/sitter-placeholder.png')
      CGImageCreateWithMask(placeholder.CGImage, SitterCircleView.maskImage)
    end
  end

  def self.sitterImage(sitter)
    return self.placeholderImage unless sitter and sitter.image
    CGImageCreateWithMask(sitter.image.CGImage, SitterCircleView.maskImage)
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
