//
//  SobelAnalyser.m
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 20.02.11.
//  Copyright 2011 Rhelba Software. All rights reserved.
//

#import "SobelAnalyser.h"

#define kDefaultSobelThreshold 0.35f


@implementation SobelAnalyser

@synthesize delegate;
@synthesize imageWidth;
@synthesize imageHeight;
@synthesize sobelThreshold;


#pragma mark - 'Public' methods

- (BOOL)didEnterInkFromTopAtPoint:(CGPoint)point
{
    BOOL didEnter = NO;
    
    int x = point.x;
    int y = point.y;
    
    if ((x > 1) && (x < imageWidth - 1) && (y > 1) && (y < imageHeight - 1)) {
        unsigned char gradientAverage0 = (  sobelArray[x - 1 + (y - 2) * imageWidth]
                                          + sobelArray[x     + (y - 2) * imageWidth]
                                          + sobelArray[x + 1 + (y - 2) * imageWidth]
                                          + sobelArray[x - 1 + (y - 1) * imageWidth]
                                          + sobelArray[x +     (y - 1) * imageWidth]
                                          + sobelArray[x + 1 + (y - 1) * imageWidth]
                                          + sobelArray[x - 1 +  y      * imageWidth]
                                          + sobelArray[x     +  y      * imageWidth]
                                          + sobelArray[x + 1 +  y      * imageWidth]) / 9;
        unsigned char gradientAverage  = (  sobelArray[x - 1 + (y - 1) * imageWidth]
                                          + sobelArray[x     + (y - 1) * imageWidth]
                                          + sobelArray[x + 1 + (y - 1) * imageWidth]
                                          + sobelArray[x - 1 +  y      * imageWidth]
                                          + sobelArray[x     +  y      * imageWidth]
                                          + sobelArray[x + 1 +  y      * imageWidth]
                                          + sobelArray[x - 1 + (y + 1) * imageWidth]
                                          + sobelArray[x     + (y + 1) * imageWidth]
                                          + sobelArray[x + 1 + (y + 1) * imageWidth]) / 9;
        
        unsigned char entryThreshold = 127 * (1 + self.sobelThreshold);
        didEnter = (gradientAverage0 >= entryThreshold) && (gradientAverage < entryThreshold);
    }
    
    return didEnter;
}


- (BOOL)didEnterInkFromLeftAtPoint:(CGPoint)point
{
    BOOL didEnter = NO;
    
    int x = point.x;
    int y = point.y;
    
    if ((x > 1) && (x < imageWidth - 1) && (y > 1) && (y < imageHeight - 1)) {
        unsigned char gradientAverage0 = (  sobelArray[x - 2 + (y - 1) * imageWidth]
                                          + sobelArray[x - 1 + (y - 1) * imageWidth]
                                          + sobelArray[x     + (y - 1) * imageWidth]
                                          + sobelArray[x - 2 +  y      * imageWidth]
                                          + sobelArray[x - 1 +  y      * imageWidth]
                                          + sobelArray[x     +  y      * imageWidth]
                                          + sobelArray[x - 2 + (y + 1) * imageWidth]
                                          + sobelArray[x - 1 + (y + 1) * imageWidth]
                                          + sobelArray[x     + (y + 1) * imageWidth]) / 9;
        unsigned char gradientAverage  = (  sobelArray[x - 1 + (y - 1) * imageWidth]
                                          + sobelArray[x     + (y - 1) * imageWidth]
                                          + sobelArray[x + 1 + (y - 1) * imageWidth]
                                          + sobelArray[x - 1 +  y      * imageWidth]
                                          + sobelArray[x     +  y      * imageWidth]
                                          + sobelArray[x + 1 +  y      * imageWidth]
                                          + sobelArray[x - 1 + (y + 1) * imageWidth]
                                          + sobelArray[x     + (y + 1) * imageWidth]
                                          + sobelArray[x + 1 + (y + 1) * imageWidth]) / 9;
        
        unsigned char entryThreshold = 127 * (1 + self.sobelThreshold);
        didEnter = (gradientAverage0 >= entryThreshold) && (gradientAverage < entryThreshold);
    }
    
    return didEnter;
}


#pragma mark - Lifecycle & housekeeping

- (id)initWithSobelArray:(unsigned char *)array ofSize:(CGSize)size
{
    self = [super init];
    
    if (self && array) {
        imageWidth = size.width;
        imageHeight = size.height;
        sobelArray = array;
        sobelThreshold = kDefaultSobelThreshold;
    }
    
    return self;
}


- (void)dealloc
{
    sobelArray = nil;
}

@end
