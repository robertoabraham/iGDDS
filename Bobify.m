#import "Bobify.h"

@implementation NSBezierPath (Bobify)


- (NSBezierPath *) bobify
{
    NSPoint *pts = malloc(3*sizeof(NSPoint));
    NSBezierPathElement elem;
    int i,j;
    for (i=0;i<[self elementCount];i++) {
        elem=[self elementAtIndex:i associatedPoints:pts];
        switch (elem) {
            case NSMoveToBezierPathElement:
            case NSLineToBezierPathElement:
                //single point per element
                pts->x = -1.0 + roundf(pts->x)+0.5;
                pts->y = -1.0 + roundf(pts->y)+0.5;
                [self setAssociatedPoints:pts atIndex:i];
            case NSCurveToBezierPathElement:
                //control point 1, control point 2, end point
                for(j=0;j<3;j++){
                    (pts+j)->x = -1.0 + roundf((pts+j)->x)+0.5;
                    (pts+j)->y =-1.0 + roundf((pts+j)->y)+0.5;
                }
                [self setAssociatedPoints:pts atIndex:i];
            default:
                break;
        }
    }
    free(pts);
    return self;
}

@end
