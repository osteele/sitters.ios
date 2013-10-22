#import "UIBezierPath-OSUtils.h"

@implementation UIBezierPath (OSUtils)

void applyFunctionToPathElement(void *info, const CGPathElement *element) {
    CGPathApplierBlock block = (CGPathApplierBlock) info;
    block(element->type, element->points);
}

- (void)applyToPathElements:(CGPathApplierBlock) block {
    CGPathApply(self.CGPath, block, applyFunctionToPathElement);
}

- (void)appendDestinationPointsToArray:(NSMutableArray *) array {
    [self applyToPathElements: ^(CGPathElementType type, const CGPoint * points) {
        switch (type) {
        case kCGPathElementAddLineToPoint:
        case kCGPathElementMoveToPoint:
            // NSLog(@"M %d, %d", (int) points[0].x, (int) points[0].y);
            [array addObject: [NSValue valueWithCGPoint:points[0]]];
            break;
        case kCGPathElementAddQuadCurveToPoint:
            // NSLog(@"Q %f, %f", points[1].x, points[1].y);
            [array addObject: [NSValue valueWithCGPoint:points[1]]];
            break;
        case kCGPathElementAddCurveToPoint:
            // NSLog(@"C %f, %f", points[2].x, points[2].y);
            [array addObject: [NSValue valueWithCGPoint:points[2]]];
            break;
        case kCGPathElementCloseSubpath:
            break;
        }
    }];
}

- (int)getDestinationPointsArray:(CGPoint []) array {
    __block int i = 0;
    [self applyToPathElements: ^(CGPathElementType type, const CGPoint * points) {
        switch (type) {
        case kCGPathElementAddLineToPoint:
        case kCGPathElementMoveToPoint:
            if (array) array[i] = points[0];
            i++;
            break;
        case kCGPathElementAddQuadCurveToPoint:
            if (array) array[i] = points[1];
            i++;
            break;
        case kCGPathElementAddCurveToPoint:
            if (array) array[i] = points[2];
            i++;
            break;
        case kCGPathElementCloseSubpath:
            break;
        }
    }];
    return i;
}

@end
