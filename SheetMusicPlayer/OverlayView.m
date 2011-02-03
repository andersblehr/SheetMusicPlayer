//
//  OverlayView.m
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 28.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OverlayView.h"


@implementation OverlayView

@synthesize plotColour;
@synthesize plotPoints;


- (void)plotImagePoint:(CGPoint)imagePoint
{
    [self plotImagePoint:imagePoint withColour:[UIColor yellowColor]];
}


- (void)plotImagePoint:(CGPoint)imagePoint withColour:(UIColor *)colour
{
    self.plotColour = colour;
    
    [plotPoints addObject:[NSValue valueWithCGPoint:CGPointMake(imagePoint.x * scaleFactor, imagePoint.y * scaleFactor)]];
    
    [self setNeedsDisplay];
}


- (id)initWithImageView:(UIImageView *)imageView
{
    [imageView retain];
    
    float imageWidth = [imageView image].size.width;
    float imageHeight = [imageView image].size.height;
    float sobelFrameWidth = [imageView frame].size.width;
    float sobelFrameHeight = [imageView frame].size.height;
    float sobelImageAspectRatio = (float)imageWidth / (float)imageHeight;
    float sobelFrameAspectRatio = sobelFrameWidth / sobelFrameHeight;
    float overlayWidth;
    float overlayHeight;
    float overlayOriginX;
    float overlayOriginY;

    [imageView release];
    
    scaleFactor = sobelFrameWidth / imageWidth;
    
    // Compute position and bounds for overlay view so it exactly matches the image
    if ((sobelImageAspectRatio >= 1) || (sobelImageAspectRatio >= sobelFrameAspectRatio)) {
        // TODO: Support landscape orientation as well (needed?)
        overlayWidth = sobelFrameWidth;
        overlayHeight = imageHeight * scaleFactor;
        overlayOriginX = 0;
        overlayOriginY = (sobelFrameHeight - overlayHeight) / 2;
    } else if ((sobelImageAspectRatio < 1) && (sobelImageAspectRatio < sobelFrameAspectRatio)) {
        scaleFactor = sobelFrameHeight / imageHeight; // TODO: This needs testing!
        
        overlayWidth = imageWidth * scaleFactor;
        overlayHeight = sobelFrameHeight;
        overlayOriginX = (sobelFrameWidth - overlayWidth) / 2;
        overlayOriginY = 0;
    } else {
        overlayWidth = [imageView frame].size.width;
        overlayHeight = [imageView frame].size.height;
        overlayOriginX = [imageView frame].origin.x;
        overlayOriginY = [imageView frame].origin.y;
    }

    self = [self initWithFrame:CGRectMake(overlayOriginX, overlayOriginY, overlayWidth, overlayHeight)];
    
    return self;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.plotPoints = [[NSMutableArray alloc] init];
        self.backgroundColor = [UIColor clearColor];
        self.plotColour = [UIColor yellowColor];
    }
    
    return self;
}


- (void)drawRect:(CGRect)rect
{
    if ([plotPoints count] > 0) {
        [self.plotColour set];

        for (int i = 0; i < [plotPoints count]; i++) {
            CGPoint point = [[plotPoints objectAtIndex:i] CGPointValue];

            UIBezierPath *circle = [UIBezierPath bezierPathWithArcCenter:point radius:1.f startAngle:0.f endAngle:(2 * M_PI) clockwise:YES];

            circle.lineWidth = 0;
            [circle fill];
            [circle stroke];
        }

        [plotPoints removeAllObjects];
    }

    //CGContextRef currentGraphicsContext = UIGraphicsGetCurrentContext();
    //CGContextSaveGState(currentGraphicsContext);
    //CGContextTranslateCTM(currentGraphicsContext, [self center].x, [self center].y);
    //CGContextRestoreGState(currentGraphicsContext);
}


- (void)dealloc
{
    plotColour = nil;
    
    [plotPoints release];
    [super dealloc];
}

@end
