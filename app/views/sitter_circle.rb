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

    # radius = 11
    # CGContextAddArc context, cx, 90 - 3 - radius, radius, 0, 2 * Math::PI, 0
    # CGContextSetFillColorWithColor context, UIColor.grayColor.CGColor
    # CGContextFillPath context

    # CGContextAddArc context, cx, 90 - 2 - radius, radius, 0, 2 * Math::PI, 0
    # CGContextSetFillColorWithColor context, UIColor.whiteColor.CGColor
    # CGContextFillPath context
  end

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
