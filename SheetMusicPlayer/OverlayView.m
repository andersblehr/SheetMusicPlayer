//
//  OverlayView.m
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 28.01.11.
//  Copyright 2011 Rhelba Software. All rights reserved.
//

#import "OverlayView.h"
#import <QuartzCore/QuartzCore.h>


@implementation OverlayView

@synthesize plotPointsWithColour;


#pragma mark - Class methods

+ (Class)layerClass
{
    return [CATiledLayer class];
}


#pragma mark - 'Private' methods

- (CGPoint)translatePoint:(CGPoint)point
{
    CGFloat xTranslated = scaleFactor * point.x + defaultOrigin.x;
    CGFloat yTranslated = scaleFactor * point.y + defaultOrigin.y;
    
    return CGPointMake(xTranslated, yTranslated);
}


#pragma mark - Lifecycle & housekeeping

- (id)initWithFrame:(CGRect)frame imageSize:(CGSize)imageSize
{
    self = [super initWithFrame:frame];
    
    if (self) {
        CATiledLayer *thisTiledLayer = (CATiledLayer*)self.layer;
        
        thisTiledLayer.levelsOfDetail = 5;
        thisTiledLayer.levelsOfDetailBias = 2;
        
        self.backgroundColor = [UIColor clearColor];
        
        NSMutableDictionary *newDictionary = [[NSMutableDictionary alloc] init];
        self.plotPointsWithColour = newDictionary;
        [newDictionary release];
        
        staveLines = [[NSMutableArray alloc] init];
        
        float imageAspectRatio = imageSize.width / imageSize.height;
        float frameAspectRatio = frame.size.width / frame.size.height;
        
        scaleFactor = frame.size.width / imageSize.width;
        
        if ((imageAspectRatio >= 1) || (imageAspectRatio >= frameAspectRatio)) {
            defaultOrigin.x = 0;
            defaultOrigin.y = (frame.size.height - imageSize.height * scaleFactor) / 2;
        } else if ((imageAspectRatio < 1) && (imageAspectRatio < frameAspectRatio)) {
            scaleFactor = frame.size.height / imageSize.height; // Test!
            
            defaultOrigin.x = (frame.size.width - imageSize.width * scaleFactor) / 2;
            defaultOrigin.y = 0;
        } else {
            defaultOrigin.x = frame.origin.x;
            defaultOrigin.y = frame.origin.y;
        }
    }
    
    return self;
}


- (void)drawRect:(CGRect)rect
{
    // Left empty to indicate that drawLayer:inContext: should be invoked.
}


-(void)drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
    UIColor *plotColour;
    NSEnumerator *enumerator = [plotPointsWithColour keyEnumerator];
    
    while ((plotColour = [enumerator nextObject])) {
        const CGFloat *rgba = CGColorGetComponents([plotColour CGColor]);
        CGContextSetRGBStrokeColor(context, *rgba, *(rgba + 1), *(rgba + 2), *(rgba + 3));
        CGContextSetRGBFillColor(context, *rgba, *(rgba + 1), *(rgba + 2), *(rgba + 3));
        
        NSArray *plotPoints = [plotPointsWithColour objectForKey:plotColour];
        
        for (int i = 0; i < [plotPoints count]; i++) {
            CGPoint plotPoint = [[plotPoints objectAtIndex:i] CGPointValue];
            CGPoint transPoint = [self translatePoint:plotPoint];
            
            CGContextBeginPath(context);
            CGContextAddArc(context, transPoint.x, transPoint.y, 1.f, 0.f, 2 * M_PI, 1);
            CGContextStrokePath(context);
            CGContextFillPath(context);
        }
    }    
    
    CGContextSetRGBStrokeColor(context, 0.0, 1.0, 1.0, 1.0); // Cyan
    
    for (int i = 0; i < [staveLines count]; i++) {
        NSArray *staveLinePoints = [staveLines objectAtIndex:i];

        CGPoint startPoint = [[staveLinePoints objectAtIndex:0] CGPointValue];
        CGPoint transPoint = [self translatePoint:startPoint];
        
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, transPoint.x, transPoint.y);
        
        for (int p = 1; p < [staveLinePoints count]; p++) {
            CGPoint nextPoint = [[staveLinePoints objectAtIndex:p] CGPointValue];
            transPoint = [self translatePoint:nextPoint];
            
            CGContextAddLineToPoint(context, transPoint.x, transPoint.y);
        }
        
        CGContextStrokePath(context);
    }
}


- (void)dealloc
{
    self.plotPointsWithColour = nil;
    [staveLines release];
    
    [super dealloc];
}


#pragma mark - SobelAnalyserDelegate methods

- (void)plotImagePoint:(CGPoint)imagePoint
{
    [self plotImagePoint:imagePoint withColour:[UIColor yellowColor]];
}


- (void)plotImagePoint:(CGPoint)imagePoint withColour:(UIColor *)colour
{
    NSMutableArray *pointArray = [plotPointsWithColour objectForKey:colour];
    
    if (!pointArray) {
        pointArray = [[NSMutableArray alloc] init];
        [plotPointsWithColour setObject:pointArray forKey:colour];
        [pointArray release];
    }
    
    [pointArray addObject:[NSValue valueWithCGPoint:imagePoint]];
    
    [self setNeedsDisplay];
}


- (void)plotStaveLine:(NSArray *)staveLinePoints
{
    NSMutableArray *points = [NSMutableArray arrayWithArray:staveLinePoints];
    
    [staveLines addObject:points];
    
    for (int i = 0; i < [points count]; i++) {
        CGPoint point = [[points objectAtIndex:i] CGPointValue];
        [self plotImagePoint:point withColour:[UIColor redColor]];
    }
    
    [self setNeedsDisplay];
}

@end
