//
//  ImageAnalyser.m
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 31.01.11.
//  Copyright 2011 Rhelba Software. All rights reserved.
//

#import "MusicRecogniser.h"
#import "SobelAnalyser.h"
#import "StaveLocator.h"


@implementation MusicRecogniser

@dynamic grayscaleImage;
@dynamic sobelImage;
@synthesize sobelThreshold;
@synthesize sobelAnalyser;

#define kMaxImageDimension 2048.f
#define kDefaultSobelThreshold 0.35f
#define kSignalThreshold 5


#pragma mark - Getters & setters for @dynamic properties

- (void)setGrayscaleImage:(UIImage *)sourceImage
{
    if (sourceImage) {
        UIImage *sizedSourceImage = sourceImage;
        
        size_t sourceWidth = sourceImage.size.width;
        size_t sourceHeight = sourceImage.size.height;
        
        // Resize image if larger than max dimensions
        if ((sourceWidth > kMaxImageDimension) || (sourceHeight > kMaxImageDimension)) {
            float scaleFactor = kMaxImageDimension / ((sourceWidth > sourceHeight) ? sourceWidth : sourceHeight);
            
            CGSize scaledSize = CGSizeMake(scaleFactor * sourceWidth, scaleFactor * sourceHeight);
            UIGraphicsBeginImageContext(scaledSize);
            [sourceImage drawInRect:CGRectMake(0, 0, scaledSize.width, scaledSize.height)];
            sizedSourceImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        
        // Create pixel arrays and align Quartz coordinate system with UIKit's
        CGImageRef sourceImageCG = [sizedSourceImage CGImage];
        
        size_t cgSourceWidth = CGImageGetWidth(sourceImageCG);
        size_t cgSourceHeight = CGImageGetHeight(sourceImageCG);
        CGFloat translationWidth = cgSourceWidth;
        CGFloat translationHeight = cgSourceHeight;
        CGFloat rotationRadians = 0;
        
        UIImageOrientation sourceOrientation = [sizedSourceImage imageOrientation];
        
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
        CGImageRef grayscaleImageCG = CGBitmapContextCreateImage(grayscaleContext);
        grayscaleImage = [UIImage imageWithCGImage:grayscaleImageCG];
        
        CFRelease(grayscaleImageCG);
        CGContextRelease(grayscaleContext);
    } else {
        grayscaleImage = nil;
    }
}


- (UIImage *)grayscaleImage
{
    return grayscaleImage;
}


- (void)setSobelImage:(UIImage *)image
{
    sobelImage = nil;
    
    if (image) {
        self.grayscaleImage = image;
        sobelImage = self.sobelImage;
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
                    int Gx = (    grayscaleArray[(x + 1) + (y - 1) * imageWidth]  +
                              2 * grayscaleArray[(x + 1) + (y    ) * imageWidth]  +
                                  grayscaleArray[(x + 1) + (y + 1) * imageWidth]) -
                             (    grayscaleArray[(x - 1) + (y - 1) * imageWidth]  +
                              2 * grayscaleArray[(x - 1) + (y    ) * imageWidth]  +
                                  grayscaleArray[(x - 1) + (y + 1) * imageWidth]);
                    int Gy = (    grayscaleArray[(x - 1) + (y - 1) * imageWidth]  +
                              2 * grayscaleArray[(x    ) + (y - 1) * imageWidth]  +
                                  grayscaleArray[(x + 1) + (y - 1) * imageWidth]) -
                             (    grayscaleArray[(x - 1) + (y + 1) * imageWidth]  +
                              2 * grayscaleArray[(x    ) + (y + 1) * imageWidth]  +
                                  grayscaleArray[(x + 1) + (y + 1) * imageWidth]);
                    
                    int G = 128 + Gx + Gy;
                    sobelArray[x + y * imageWidth] = (G > 255) ? 255 : ((G < 0) ? 0 : (unsigned char)G);
                }
            }
        }
        
        CGImageRef sobelImageCG = CGBitmapContextCreateImage(sobelContext);
        sobelImage = [UIImage imageWithCGImage:sobelImageCG];
        CFRelease(sobelImageCG);
    }
    
    return sobelImage;
}


#pragma mark - 'Public' methods

- (BOOL)imageContainsMusic
{
    return [staveLocator imageContainsStaves];
}


- (void)plotMusic
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

- (id)initWithImage:(UIImage *)image
{
    self = [super init];
    
    if (self) {
        self.grayscaleImage = image;
        self.sobelImage = nil;
        self.sobelThreshold = kDefaultSobelThreshold;
        
        sobelAnalyser = [[SobelAnalyser alloc] initWithSobelArray:sobelArray ofSize:CGSizeMake(imageWidth, imageHeight)];
        staveLocator = [[StaveLocator alloc] initWithSobelAnalyser:sobelAnalyser];
    }
    
    return self;
}


- (void)didReceiveMemoryWarning
{
    // TODO: Need to do something..
}


- (void)dealloc
{
    self.grayscaleImage = nil;
    self.sobelImage = nil;
    
    CGContextRelease(sobelContext);
    free(sobelArray);

    if (grayscaleArray) {
        free(grayscaleArray);
    }
}

@end
