class SitterCircle < UIView
  attr_accessor :dataSource
  attr_accessor :dataIndex

  def self.new
    view = alloc.initWithFrame(CGRectZero)
    view
  end

  # layout do
  #   subview UILabel, text: 'ok', width: 100, height: 20, left: 0, top: 0
  # end

  # def initWithFrame(frame)
  #     # subview UILabel, :square_label, :view_recommended
  #   self
  # end

  def drawRect(rect)
    context = UIGraphicsGetCurrentContext()

    radius = cx = cy = 90 / 2
    radius -= 1
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
