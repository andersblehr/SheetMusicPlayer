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
@synthesize plotColour;
@synthesize plotPoints;


- (void)plotImagePoint:(CGPoint)imagePoint
{
    [self plotImagePoint:imagePoint withColour:[UIColor yellowColor]];
}


- (void)plotImagePoint:(CGPoint)imagePoint withColour:(UIColor *)colour
{
    self.plotColour = colour;
    
    [plotPoints addObject:[NSValue valueWithCGPoint:CGPointMake(imagePoint.x, imagePoint.y)]];
    
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
        self.plotPoints = [[NSMutableArray alloc] init];
        self.plotColour = [UIColor yellowColor];
    }
    
    return self;
}


- (void)drawRect:(CGRect)rect
{
    self.frame = CGRectMake(contentOffset.x, contentOffset.y, self.frame.size.width, self.frame.size.height);

    if ([plotPoints count] > 0) {
        [self.plotColour set];
        
        for (int i = 0; i < [plotPoints count]; i++) {
            CGPoint point = [[plotPoints objectAtIndex:i] CGPointValue];
            
            float translatedPointX = scaleFactor * zoomScale * point.x + zoomScale * defaultOrigin.x - contentOffset.x;
            float translatedPointY = scaleFactor * zoomScale * point.y + zoomScale * defaultOrigin.y - contentOffset.y;

            CGPoint translatedPoint = CGPointMake(translatedPointX, translatedPointY);
            
            UIBezierPath *circle = [UIBezierPath bezierPathWithArcCenter:translatedPoint radius:zoomScale startAngle:0.f endAngle:(2 * M_PI) clockwise:YES];
            
            circle.lineWidth = 0;
            [circle fill];
            [circle stroke];
        }
    }
}


- (void)dealloc
{
    plotColour = nil;
    
    [plotPoints release];
    [super dealloc];
}

@end
