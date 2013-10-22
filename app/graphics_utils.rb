# Adapted from https://github.com/erica/iOS-6-Advanced-Cookbook
class UIBezierPath
  def distance(p0, p1)
    ((p2.x - p1.x) ** 2 + (p2.x - p1.x) ** 2) ** 0.5
  end

  def points
    points = NSMutableArray.array
    path = self.CGPath
    self.applyToPathElements lambda { |type, elementPoints|
      puts "called"
      # case element.type
      #   when KCGPathElementAddLineToPoint, KCGPathElementMoveToPoint
      #     points << elementPoints[0]
      #   when KCGPathElementAddQuadCurveToPoint
      #     points << elementPoints[1]
      #   when KCGPathElementAddCurveToPoint
      #     points << elementPoints[2]
      # end
    }
    return points
  end

  def length
    points = self.points
    length = 0.0
    for i in 1...points.count
      length += distance(points[i], points[i - 1])
    end
    return length
  end

  def pointPercentArray
    # Use total length to calculate the percent of path consumed at each control point
    points = self.points
    pointCount = points.count

    totalPointLength = self.length
    distanceTravelled = 0.0

    pointPercentArray = []
    pointPercentArray << 0.0

    for i in 1...pointCount
      distanceTravelled += distance(points[i], points[i-1])
      pointPercentArray << distanceTravelled / totalPointLength
    end

    # Add a final item just to stop with. Probably not needed.
    pointPercentArray << 1.0
    return pointPercentArray
  end

  def pointAtPercent(percent, withSlope:slope)
    points = self.points
    percentArray = self.pointPercentArray
    lastPointIndex = points.count - 1

    return CGPointZero if points.count == 0

    return points[0] if percent <= 0.0
    return points[lastPointIndex] if percent >= 1.0

    # Find a corresponding pair of points in the path
    index = 1
    while index < percentArray.count and percent > percentArray[index] do
      index += 1
    end

    # This should not happen.
    return points[lastPointIndex] if index > lastPointIndex

    # Calculate the intermediate distance between the two points
    point1 = points[index - 1]
    point2 = points[index]

    percent1 = percentArray[index - 1]
    percent2 = percentArray[index]
    percentOffset = (percent - percent1) / (percent2 - percent1)

    dx = point2.x - point1.x
    dy = point2.y - point1.y

    # Store dy, dx for retrieving arctan
    slope = CGPointMake(dx, dy)

    # Calculate new point
    newX = point1.x + (percentOffset * dx)
    newY = point1.y + (percentOffset * dy)
    targetPoint = CGPointMake(newX, newY)

    return [targetPoint, slope]
  end
end

class NSAttributedString
  # Adapted from https://github.com/erica/iOS-6-Advanced-Cookbook
  def drawOnPath(path, withOptions:renderingOptions)
    baseString = self
    points = path.points
    pointCount = points.count
    return if pointCount < 2

    glyphDistance = 0

    fitText = (renderingOptions & RenderStringToFit) != 0
    lineLength = fitText ? baseString.renderedWidth : path.length

    closePath = (renderingOptions & RenderStringClosePath) != 0
    path.addLineToPoint points[0] if closePath

    context = UIGraphicsGetCurrentContext()
    CGContextSaveGState context

    textPosition = CGPointMake(0, 0)
    CGContextSetTextPosition context, textPosition.x, textPosition.y

    for loc in 0...baseString.length
      range = NSMakeRange(loc, 1)
      item = baseString.attributedSubstringFromRange(range)

      glyphWidth = item.renderedWidth
      glyphDistance += glyphWidth
      percentConsumed = glyphDistance / lineLength
      break if percentConsumed > 1

      targetPoint, slope = path.pointAtPercent(percentConsumed)

      CGContextTranslateCTM context, targetPoint.x, targetPoint.y
      positionForThisGlyph = CGPointMake(textPosition.x, textPosition.y)

      angle = Math::atan(slope.y / slope.x)
      angle += M_PI if (slope.x < 0)
      CGContextRotateCTM context, angle

      positionForThisGlyph.x -= glyphWidth
      positionForThisGlyph.y -= case
        when (renderingOptions & RenderStringOutsidePath) != 0
          item.renderedHeight
        when (renderingOptions & RenderStringInsidePath) != 0
          0
        else
          item.renderedHeight / 2
      end

      item.drawAtPoint positionForThisGlyph

      CGContextRotateCTM context, -angle
      CGContextTranslateCTM context, -targetPoint.x, -targetPoint.y
    end

    CGContextRestoreGState(context)
  end

  def drawOnArc(cx, cy, radius)
    if false
      # lineWidth = self.size.width
      # lineAngle = lineWidth / radius
      # puts "angle = #{lineAngle}"
      # midpointAngle = Math::PI / 2
      # startAngle:-lineAngle/2, endAngle:lineAngle/2
      path = UIBezierPath.bezierPathWithArcCenter([cx, cy], radius:radius, startAngle:0, endAngle:90, clockwise:true)
      self.drawOnPath path, withOptions:{}
      return
    end

    context = UIGraphicsGetCurrentContext()

    aString = self
    cfLine = CTLineCreateWithAttributedString(aString)
    runs = CTLineGetGlyphRuns(cfLine)

    glyphCount = CTLineGetGlyphCount(cfLine)
    glyphWidths = [nil] * glyphCount
    glyphXs = [nil] * glyphCount
    start = glyphIndex = 0
    for run in runs
      runGlyphCount = CTRunGetGlyphCount(run)
      for runGlyphIndex in 0...runGlyphCount
        glyphWidths[glyphIndex] = glyphWidth = CTRunGetTypographicBounds(run, CFRangeMake(runGlyphIndex, 1), nil, nil, nil)
        glyphXs[glyphIndex] = start += glyphWidth
        glyphIndex += 1
      end
    end
    # puts "glyphXs = #{glyphXs} for #{string}"

    # glyphCenters = [nil] * glyphCount
    # previousOffset = 0
    # glyphXs.each_with_index do |offset, i|
    #   glyphCenters[i] = (previousOffset + offset) / 2
    #   previousOffset = offset
    # end
    # # puts "glyphCenters = #{glyphCenters}"
    # # puts "bounds.width = #{CTLineGetTypographicBounds(cfLine, nil, nil, nil)}"

    lineWidth = aString.size.width
    lineAngle = lineWidth / radius
    CGContextSaveGState context
    CGContextTranslateCTM context, cx, cy
    CGContextRotateCTM context, lineAngle / 2
    currentRunFirstGlyphIndex = 0
    for run in runs
      runGlyphCount = CTRunGetGlyphCount(run)
      for runGlyphIndex in 0...runGlyphCount
        glyphIndex = currentRunFirstGlyphIndex + runGlyphIndex
        glyphRange = CFRangeMake(runGlyphIndex, 1)
        glyphWidth = glyphWidths[glyphIndex]
        glyphAngle = glyphWidth / radius

        # glyphAngle = glyphCenters[glyphIndex] / radius

        # glyphWidth = CTRunGetTypographicBounds(runArray.first, CFRangeMake(glyphIndex, 1), nil, nil, nil)
        # imageWidth = CTRunGetImageBounds(runArray.first, context, CFRangeMake(glyphIndex, 1)).size.width
        # imageAngle = imageWidth / radius

        CGContextRotateCTM context, -glyphAngle / 2

        # CGContextSetFillColorWithColor context, (glyphIndex % 2 == 0 ? 0xA60000 : 0x00A600).uicolor.CGColor
        # CGContextFillRect context, CGRectMake(glyphWidth / 2, radius, glyphWidth, 1)
        # CGContextSetFillColorWithColor context, UIColor.blackColor.CGColor

        CGContextSetTextMatrix context, CGAffineTransformMakeTranslation(glyphWidth / 2 - glyphXs[glyphIndex], radius)
        CTRunDraw run, context, glyphRange

        CGContextRotateCTM context, -glyphAngle / 2
      end
      currentRunFirstGlyphIndex += runGlyphCount
    end
    CGContextRestoreGState context
  end
end
