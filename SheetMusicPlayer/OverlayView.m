//
//  OverlayView.m
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 28.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OverlayView.h"


@implementation OverlayView

@synthesize zoomScale;
@synthesize contentOffset;
@synthesize plotPointsWithColour;


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


- (id)initWithImageView:(UIImageView *)imageView
{
    [imageView retain];
    
    self = [self initWithFrame:imageView.frame];
    
    float imageAspectRatio = imageView.image.size.width / imageView.image.size.height;
    float frameAspectRatio = imageView.frame.size.width / imageView.frame.size.height;

    scaleFactor = imageView.frame.size.width / imageView.image.size.width;
    
    if ((imageAspectRatio >= 1) || (imageAspectRatio >= frameAspectRatio)) {
        defaultOrigin.x = 0;
        defaultOrigin.y = (imageView.frame.size.height - imageView.image.size.height * scaleFactor) / 2;
    } else if ((imageAspectRatio < 1) && (imageAspectRatio < frameAspectRatio)) {
        scaleFactor = imageView.frame.size.height / imageView.image.size.height; // Test!
        
        defaultOrigin.x = (imageView.frame.size.width - imageView.image.size.width * scaleFactor) / 2;
        defaultOrigin.y = 0;
    } else {
        defaultOrigin.x = imageView.frame.origin.x;
        defaultOrigin.y = imageView.frame.origin.y;
    }

    [imageView release];
    
    return self;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        self.zoomScale = 1.f;
        
        NSMutableDictionary *newDictionary = [[NSMutableDictionary alloc] init];
        self.plotPointsWithColour = newDictionary;
        [newDictionary release];
    }
    
    return self;
}


- (void)drawRect:(CGRect)rect
{
    self.frame = CGRectMake(contentOffset.x, contentOffset.y, self.frame.size.width, self.frame.size.height);

    UIColor *plotColour;
    NSEnumerator *enumerator = [plotPointsWithColour keyEnumerator];

    while ((plotColour = [enumerator nextObject])) {
        [plotColour set];
        
        NSArray *plotPoints = [plotPointsWithColour objectForKey:plotColour];
        
        for (int i = 0; i < [plotPoints count]; i++) {
            CGPoint point = [[plotPoints objectAtIndex:i] CGPointValue];
            
            float translatedPointX = scaleFactor * zoomScale * point.x + zoomScale * defaultOrigin.x - contentOffset.x;
            float translatedPointY = scaleFactor * zoomScale * point.y + zoomScale * defaultOrigin.y - contentOffset.y;
            
            CGPoint translatedPoint = CGPointMake(translatedPointX, translatedPointY);
            int radius = [plotColour isEqual:[UIColor redColor]] ? 2 * zoomScale : zoomScale;
            
            UIBezierPath *circle = [UIBezierPath bezierPathWithArcCenter:translatedPoint radius:radius startAngle:0.f endAngle:(2 * M_PI) clockwise:YES];
            
            [circle setLineWidth:0];
            [circle fill];
            [circle stroke];
        }
    }
}


- (void)dealloc
{
    [plotPointsWithColour release];
    
    [super dealloc];
}

@end
