class SitterCircle < UIView
  # attr_accessor :number

  def self.new(number, model)
    # self.number = number
    view = alloc.initWithFrame(CGRectZero)
    view
  end

  # def initWithFrame(frame)
  #   self
  # end

  def drawRect(rect)
    context = UIGraphicsGetCurrentContext()

    radius = cx = cy = 90 / 2
    CGContextAddArc context, cx, cy, radius, 0, 2 * Math::PI, 0
    CGContextSetFillColorWithColor context, UIColor.whiteColor.CGColor
    CGContextFillPath context

    CGContextAddArc context, cx, cy, radius, 0, 2 * Math::PI, 0
    CGContextSetStrokeColorWithColor context, UIColor.grayColor.CGColor
    CGContextStrokePath context

    radius -= 10
    CGContextAddArc context, cx, cy, radius, 0, 2 * Math::PI, 0
    CGContextSetFillColorWithColor context, "#A6A6A6".uicolor.CGColor
    CGContextFillPath context

    CGContextAddArc context, cx, cy, radius, 0, 2 * Math::PI, 0
    CGContextSetStrokeColorWithColor context, UIColor.grayColor.CGColor
    CGContextStrokePath context
  end
end
