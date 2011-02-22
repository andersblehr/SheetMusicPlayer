//
//  ImageAnalyser.m
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 31.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MusicRecogniser.h"
#import "SobelAnalyser.h"
#import "StaveLocator.h"


@implementation MusicRecogniser

@dynamic sourceImage;
@dynamic sobelImage;
@synthesize sobelThreshold;
@synthesize sobelAnalyser;

#define kMaxImageDimension 2048.f
#define kDefaultSobelThreshold 0.35f
#define kSignalThreshold 5


#pragma mark - Getters & setters for @dynamic properties

- (void)setSourceImage:(UIImage *)theSourceImage
{
    if (theSourceImage) {
        UIImage *sizedSourceImage = [theSourceImage retain];
        
        size_t uiSourceWidth = theSourceImage.size.width;
        size_t uiSourceHeight = theSourceImage.size.height;
        
        // Resize image if larger than max dimensions
        if ((uiSourceWidth > kMaxImageDimension) || (uiSourceHeight > kMaxImageDimension)) {
            float scaleFactor = kMaxImageDimension / ((uiSourceWidth > uiSourceHeight) ? uiSourceWidth : uiSourceHeight);
            
            CGSize scaledSize = CGSizeMake(scaleFactor * uiSourceWidth, scaleFactor * uiSourceHeight);
            UIGraphicsBeginImageContext(scaledSize);
            [theSourceImage drawInRect:CGRectMake(0, 0, scaledSize.width, scaledSize.height)];
            [sizedSourceImage release];
            sizedSourceImage = [UIGraphicsGetImageFromCurrentImageContext() retain];
            UIGraphicsEndImageContext();
        }
        
        [sourceImage release];
        sourceImage = sizedSourceImage;
        
        // Create pixel arrays and align Quartz coordinate system with UIKit's
        CGImageRef sourceImageCG = [sourceImage CGImage];
        
        size_t cgSourceWidth = CGImageGetWidth(sourceImageCG);
        size_t cgSourceHeight = CGImageGetHeight(sourceImageCG);
        CGFloat translationWidth = cgSourceWidth;
        CGFloat translationHeight = cgSourceHeight;
        CGFloat rotationRadians = 0;
        
        UIImageOrientation sourceOrientation = [sourceImage imageOrientation];
        
        // Handle UIKit and Quartz's differing coordinate systems
        if (sourceOrientation == UIImageOrientationUp) {
            imageWidth = cgSourceWidth;
            imageHeight = cgSourceHeight;
        } else if (sourceOrientation == UIImageOrientationDown) {
            imageWidth = cgSourceWidth;
            imageHeight = cgSourceHeight;
            rotationRadians = -M_PI;
        } else if (sourceOrientation == UIImageOrientationRight) {
            imageWidth = cgSourceHeight;
            imageHeight = cgSourceWidth;
            translationWidth = -(CGFloat)cgSourceWidth;
            translationHeight = 0;
            rotationRadians = -M_PI/2;
        } else if (sourceOrientation == UIImageOrientationLeft) {
            imageWidth = cgSourceHeight;
            imageHeight = cgSourceWidth;
            translationWidth = 0;
            translationHeight = -(CGFloat)cgSourceHeight;
            rotationRadians = M_PI/2;
        }
        
        grayscaleArray = malloc(imageWidth * imageHeight);
        sobelArray = malloc(imageWidth * imageHeight);
        
        // Convert to grayscale to preserve space (1 byte/pixel vs 4 for RGB)
        CGColorSpaceRef monochromeColourSpace = CGColorSpaceCreateDeviceGray();
        CGContextRef grayscaleContext = CGBitmapContextCreate(grayscaleArray, imageWidth, imageHeight, 8, imageWidth, monochromeColourSpace, kCGImageAlphaNone);
        sobelContext = CGBitmapContextCreate(sobelArray, imageWidth, imageHeight, 8, imageWidth, monochromeColourSpace, kCGImageAlphaNone);
        CGColorSpaceRelease(monochromeColourSpace);
        
        // Rotate & translate Quartz coordinate system to preserve image orientation
        if (sourceOrientation != UIImageOrientationUp) {
            CGContextRotateCTM(grayscaleContext, rotationRadians);
            CGContextTranslateCTM(grayscaleContext, translationWidth, translationHeight);
        }
        
        CGContextDrawImage(grayscaleContext, CGRectMake(0, 0, cgSourceWidth, cgSourceHeight), sourceImageCG);
        CGContextRelease(grayscaleContext);
    } else {
        [sourceImage release];
        sourceImage = nil;
    }
}


- (UIImage *)sourceImage
{
    return sourceImage;
}


- (void)setSobelImage:(UIImage *)image
{
    [sobelImage release];
    sobelImage = nil;
    
    if (image) {
        [image retain];
        self.sourceImage = image;
        sobelImage = [self.sobelImage retain];
        [image release];
    }
}


- (UIImage *)sobelImage
{
    if (!sobelImage) {
        for (int y = 0; y < imageHeight; y++) {
            for (int x = 0; x < imageWidth; x++) {
                if ((y == 0) || (y == imageHeight - 1) || (x == 0) || (x == imageWidth - 1))
                    sobelArray[x + y * imageWidth] = 127;
                else {
                    // Obtain X and Y gradients using the Sobel operator
                    int Gx = (    grayscaleArray[(x + 1) + (y - 1) * imageWidth] +
                              2 * grayscaleArray[(x + 1) + (y    ) * imageWidth] +
                                  grayscaleArray[(x + 1) + (y + 1) * imageWidth]) -
                             (    grayscaleArray[(x - 1) + (y - 1) * imageWidth] +
                              2 * grayscaleArray[(x - 1) + (y    ) * imageWidth] +
                                  grayscaleArray[(x - 1) + (y + 1) * imageWidth]);
                    int Gy = (    grayscaleArray[(x - 1) + (y - 1) * imageWidth] +
                              2 * grayscaleArray[(x    ) + (y - 1) * imageWidth] +
                                  grayscaleArray[(x + 1) + (y - 1) * imageWidth]) -
                             (    grayscaleArray[(x - 1) + (y + 1) * imageWidth] +
                              2 * grayscaleArray[(x    ) + (y + 1) * imageWidth] +
                                  grayscaleArray[(x + 1) + (y + 1) * imageWidth]);
                    
                    int G = 128 + Gx + Gy;
                    sobelArray[x + y * imageWidth] = (G > 255) ? 255 : ((G < 0) ? 0 : (unsigned char)G);
                }
            }
        }
        
        CGImageRef sobelImageCG = CGBitmapContextCreateImage(sobelContext);
        sobelImage = [[UIImage imageWithCGImage:sobelImageCG] retain];
        CFRelease(sobelImageCG);
    }
    
    return sobelImage;
}


#pragma mark - 'Public' methods

- (BOOL)imageContainsMusic
{
    return [staveLocator imageContainsStaves];
}


- (void)plotStaves
{
    [staveLocator locateStaves];
}


- (void)plotInkPointsAtOffset:(float)offset
{
    for (int y = 0; y < imageHeight; y++) {
        CGPoint currentPoint = CGPointMake(offset * imageWidth, y);
        
        if ([sobelAnalyser didEnterInkFromTopAtPoint:currentPoint]) {
            [sobelAnalyser.delegate plotImagePoint:currentPoint];
        }
    }
}


#pragma mark - Lifecycle & housekeeping

- (id)initWithImage:(UIImage *)anImage
{
    self = [super init];
    
    if (self) {
        self.sourceImage = anImage;
        self.sobelImage = nil;
        self.sobelThreshold = kDefaultSobelThreshold;
        
        sobelAnalyser = [[SobelAnalyser alloc] initWithSobelArray:sobelArray ofSize:CGSizeMake(imageWidth, imageHeight)];
        staveLocator = [[StaveLocator alloc] initWithSobelAnalyser:sobelAnalyser];
    }
    
    return self;
}


- (void)dealloc
{
    self.sourceImage = nil;
    self.sobelImage = nil;
    
    CGContextRelease(sobelContext);
    free(grayscaleArray);
    free(sobelArray);
    
    [staveLocator release];;
    
    [super dealloc];
}

@end
