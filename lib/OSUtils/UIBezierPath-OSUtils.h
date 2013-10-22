#import <Foundation/Foundation.h>

typedef void (^CGPathApplierBlock) (
   CGPathElementType type,
   const CGPoint * points
);

@interface UIBezierPath (OSUtils)
- (void) applyToPathElements:(CGPathApplierBlock) function;

- (void) appendDestinationPointsToArray:(NSMutableArray *) points;

- (int) getDestinationPointsArray:(CGPoint []) points;

@end
