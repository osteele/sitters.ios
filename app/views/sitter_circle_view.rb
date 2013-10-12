class SitterCircleView < UIView
  attr_accessor :sitter

  def self.new
    view = alloc.initWithFrame(CGRectZero)
    view
  end

  def drawRect(rect)
    bounds = CGRectMake(0, 0, self.size.width, self.size.height)

    context = UIGraphicsGetCurrentContext()
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

    if false
      # CGContextSelectFont context, fontName, fontSize, KCGEncodingMacRoman
      CGContextSetFillColorWithColor context, UIColor.blackColor.CGColor
      labelRect = CGRectMake(cx - 40, 0, cx + 40, 2 * labelCircleRadius)
      # labelRect = CGRectMake(0, 0, 100, 100)
      labelText.drawInRect labelRect, withFont:UIFont.fontWithName("HelveticaNeue", size:14) #, lineBreakMode:0
    end

    # Sitter name
    radius = 26
    drawArcText context, sitter.first_name.upcase, cx, cy, radius if NSUserDefaults.standardUserDefaults[:arc_text]
  end

  def newDrawArcText(context, string, cx, cy, radius)
    kern = true
    radius += 10
    fontName = "HelveticaNeue"
    fontSize = 10

    CGContextSaveGState context
    CGContextSelectFont context, fontName, fontSize, KCGEncodingMacRoman
    CGContextSetFillColorWithColor context, UIColor.blackColor.CGColor

    line = CTLineCreateWithAttributedString
    glyphCount = CTLineGetGlyphCount(line)
    PrepareGlyphArcInfo(line, glyphCount, glyphArcInfo)
    runArray = CTLineGetGlyphRuns(line)
    puts "runArray = #{runArray}"
    puts "runArray.length = #{CFArrayGetCount(runArray)}"
    run = runArray[0]
    runGlyphCount = CTRunGetGlyphCount(run)
    puts "runGlyphCount = #{runGlyphCount}"
    glyphOffset = 0

    CGContextSetTextPosition(context, cx, 10)
    for runGlyphIndex in 0...runGlyphCount
      CGContextRotateCTM(context, -(glyphArcInfo[runGlyphIndex + glyphOffset].angle))
      glyphWidth = glyphArcInfo[runGlyphIndex + glyphOffset].width
      positionForThisGlyph = CGPointMake(textPosition.x - glyphWidth / 2, textPosition.y)
      textPosition.x -= glyphWidth
      CGAffineTransform textMatrix = CTRunGetTextMatrix(run)
      textMatrix.tx = positionForThisGlyph.x
      textMatrix.ty = positionForThisGlyph.y
      CGContextSetTextMatrix context, textMatrix
      CTRunDraw run, context, CFRangeMake(runGlyphIndex, 1)
    end
    CGContextRestoreGState context
  end

  def drawArcText(context, string, cx, cy, radius)
    kern = true
    radius += 10
    fontName = "HelveticaNeue"
    fontSize = 10
    CGContextSelectFont context, fontName, fontSize, KCGEncodingMacRoman
    CGContextSetFillColorWithColor context, UIColor.blackColor.CGColor
    if kern
      text_width = string.sizeWithAttributes({}).width
      text_angle = text_width * 2 * Math::PI / (radius * 2 * Math::PI)
      # puts "#{string} width=#{text_width} angle=#{text_angle * 360}"
      next_angle = Math::PI / 2 + text_angle / 2
    end
    for i in 0...string.length
      # angle = -Math::PI / 2 + 11 * (i - string.length / 2) * Math::PI / 180
      if kern
        letter_width = string[i].sizeWithAttributes({}).width
        letter_angle = letter_width / text_width * text_angle
        angle = next_angle - letter_angle / 2
        # puts "#{string[i]} (width=#{letter_width}, angle=#{letter_angle * 360}) at angle=#{angle}"
        next_angle -= letter_angle
      end
      dx = radius * Math.cos(angle)
      dy = radius * Math.sin(angle)
      xform = CGAffineTransformMakeRotation(angle - Math::PI / 2)
      CGContextSetTextMatrix context, xform
      CGContextShowTextAtPoint context, cx + dx, cy + dy, string[i], 1
    end
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
