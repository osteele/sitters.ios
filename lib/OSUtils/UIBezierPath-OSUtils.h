#import <Foundation/Foundation.h>

typedef void (*CGPathElementApplierFunction) (
   CGPathElementType type,
   const CGPoint * points
);

@interface UIBezierPath (OSUtils)
- (void) applyToPathElements:(id) function;

@end
