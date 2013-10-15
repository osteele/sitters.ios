module DrawingUtils
  def self.drawArcText(context, string, cx, cy, radius, font)
    textAttributes = { NSFontAttributeName => font }
    astring = NSAttributedString.alloc.initWithString(string, attributes:textAttributes)

    cfLine = CTLineCreateWithAttributedString(astring)
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

    CGContextSelectFont context, font.fontName, font.pointSize, KCGEncodingMacRoman
    CGContextSetFillColorWithColor context, UIColor.blackColor.CGColor

    lineWidth = astring.size.width
    lineAngle = lineWidth / radius
    CGContextSaveGState context
    CGContextTranslateCTM context, cx, cy
    CGContextRotateCTM context, lineAngle / 2
    currentRunFirstGlyphIndex = 0
    for run in runs
      runGlyphCount = CTRunGetGlyphCount(run)
      for runGlyphIndex in 0...runGlyphCount
        glyphIndex = currentRunFirstGlyphIndex + runGlyphIndex
        glyph = string[glyphIndex]
        glyphWidth = glyphWidths[glyphIndex]
        glyphAngle = glyphWidth / radius

        # glyphAngle = glyphCenters[glyphIndex] / radius

        # glyphWidth = CTRunGetTypographicBounds(runArray.first, CFRangeMake(glyphIndex, 1), nil, nil, nil)
        # imageWidth = CTRunGetImageBounds(runArray.first, context, CFRangeMake(glyphIndex, 1)).size.width
        # imageAngle = imageWidth / radius

        CGContextRotateCTM context, -glyphAngle / 2
        CGContextShowTextAtPoint context, -glyphWidth / 2, radius, glyph, 1
        CGContextRotateCTM context, -glyphAngle / 2
      end
      currentRunFirstGlyphIndex += runGlyphCount
    end
    CGContextRestoreGState context
  end
end