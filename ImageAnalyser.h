//
//  ImageAnalyser.h
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 31.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StaveLocator.h"

@protocol ImageAnalyserDelegate <NSObject>
@required
- (void)plotImagePoint:(CGPoint)imagePoint;
- (void)plotImagePoint:(CGPoint)imagePoint withColour:(UIColor *)colour;

@end


@interface ImageAnalyser : NSObject {
@private
    id <ImageAnalyserDelegate> delegate;
    
    UIImage *sourceImage;
    size_t imageWidth;
    size_t imageHeight;
    
    unsigned char *grayscaleArray;
    unsigned char *sobelArray;
    CGContextRef sobelContext;
    
    StaveLocator *staveLocator;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) UIImage *sourceImage;
@property (nonatomic, retain) StaveLocator *staveLocator;

- (UIImage *)obtainSobelImage;
- (void)locateStavesUsingThreshold:(float)threshold;
- (id)initWithImage:(UIImage *)anImage;

@end
