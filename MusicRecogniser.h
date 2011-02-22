//
//  ImageAnalyser.h
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 31.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SobelAnalyser.h"
#import "StaveLocator.h"

@interface MusicRecogniser : NSObject {
@private
    UIImage *sourceImage;
    UIImage *sobelImage;
    size_t imageWidth;
    size_t imageHeight;
    
    float sobelThreshold;
    unsigned char *grayscaleArray;
    unsigned char *sobelArray;
    CGContextRef sobelContext;
    
    SobelAnalyser *sobelAnalyser;
    StaveLocator *staveLocator;
}

@property (nonatomic, retain) UIImage *sourceImage;
@property (nonatomic, retain) UIImage *sobelImage;
@property (nonatomic, assign) float sobelThreshold;
@property (nonatomic, retain) SobelAnalyser *sobelAnalyser;

- (BOOL)imageContainsMusic;
- (void)plotStaves;
- (id)initWithImage:(UIImage *)anImage;
@end
