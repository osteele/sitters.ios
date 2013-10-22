#import "UIBezierPath-OSUtils.h"

@implementation UIBezierPath (OSUtils)

void applyFunctionToPathElement(void *info, const CGPathElement *element) {
    CGPathElementApplierFunction * function = (CGPathElementApplierFunction *) info;
    NSLog(@"applyFunctionToPathElement");
    (*function)(element->type, element->points);
}

- (void)applyToPathElements:(id) function {
    NSLog(@"applyToPathElements");
    CGPathApply(self.CGPath, function, applyFunctionToPathElement);
}

@end
