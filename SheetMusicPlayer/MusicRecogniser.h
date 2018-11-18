//
//  ImageAnalyser.h
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 31.01.11.
//  Copyright 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SobelAnalyser.h"
#import "StaveLocator.h"

@interface MusicRecogniser : NSObject {
@private
    UIImage *grayscaleImage;
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

@property (nonatomic, retain) UIImage *grayscaleImage;
@property (nonatomic, retain) UIImage *sobelImage;
@property (nonatomic, assign) float sobelThreshold;
@property (nonatomic, retain) SobelAnalyser *sobelAnalyser;

- (BOOL)imageContainsMusic;
- (void)plotMusic;
- (id)initWithImage:(UIImage *)anImage;
- (void)didReceiveMemoryWarning;
@end
