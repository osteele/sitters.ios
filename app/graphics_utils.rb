module GraphicsUtils
  def self.imageForBounds(bounds, &block)
    UIGraphicsBeginImageContextWithOptions bounds.size, false, 0
    context = UIGraphicsGetCurrentContext()
    block.call context
    image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
  end
end

class NSAttributedString
  # Exposed for debugging.
  # TODO remove these or move them to an options argument
  TextArcSettings = {
    dRadius: 0,
    mid: -0.5,
    tracking: 1.05,
    left: 0.5,
    baseline: -0.5
  }

  # Draws the attributed string along an arc of the circle centered at (cx, cy), with radius radius.
  def drawOnArc(cx, cy, radius)
    radius += TextArcSettings[:dRadius]
    tracking = TextArcSettings[:tracking]

    context = UIGraphicsGetCurrentContext()
    lineWidth = self.size.width * tracking
    lineHeight = self.size.height
    radius += lineHeight / 2
    lineAngle = lineWidth / radius
    cursorAngle = Math::PI / 2 - lineAngle / 2

    dy = lineHeight * TextArcSettings[:baseline]
    radius += dy

    for glyphIndex in 0...self.length
      glyphRange = NSMakeRange(glyphIndex, 1)
      glyphString = self.attributedSubstringFromRange(glyphRange)
      glyphWidth = glyphString.size.width * tracking
      glyphAngle = glyphWidth / radius
      cursorAngle += glyphAngle * TextArcSettings[:left]

      CGContextSaveGState context
      CGContextTranslateCTM context, cx, cy
      CGContextScaleCTM context, -1, 1
      CGContextTranslateCTM context, radius * Math.cos(cursorAngle), radius * Math.sin(cursorAngle)
      CGContextRotateCTM context, cursorAngle + Math::PI / 2
      glyphPosition = [-glyphWidth / 2, dy]
      glyphString.drawAtPoint glyphPosition
      CGContextRestoreGState context

      cursorAngle += glyphAngle - glyphAngle * TextArcSettings[:left]
    end
  end
end
