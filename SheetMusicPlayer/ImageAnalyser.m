//
//  ImageAnalyser.m
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 31.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ImageAnalyser.h"
#import "StaveLocator.h"


@implementation ImageAnalyser

@synthesize delegate;
@dynamic sourceImage;
@synthesize sobelThreshold;
@synthesize staveLocator;


#define kMaxImageDimension 2048.f
#define kDefaultThreshold 0.35f


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


#pragma mark - 'Private' methods

- (void)resetSobelState
{
    sobelState = SobelStateOutside;
}


- (BOOL)didEnterInkAtPoint:(CGPoint)imagePoint
{
    BOOL didEnter = NO;
    
    int x = imagePoint.x;
    int y = imagePoint.y;
    
    unsigned char gradientAverage = sobelArray[x + y * imageWidth];
    
    if ((x > 0) && (x < imageWidth - 1) && (y > 0) && (y < imageHeight - 1)) {
        gradientAverage = (  gradientAverage
                           + sobelArray[x - 1 + (y - 1) * imageWidth]
                           + sobelArray[x     + (y - 1) * imageWidth]
                           + sobelArray[x + 1 + (y - 1) * imageWidth]
                           + sobelArray[x - 1 +  y      * imageWidth]
                           + sobelArray[x + 1 +  y      * imageWidth]
                           + sobelArray[x - 1 + (y + 1) * imageWidth]
                           + sobelArray[x     + (y + 1) * imageWidth]
                           + sobelArray[x + 1 + (y + 1) * imageWidth]) / 9;
    }
    
    if (gradientAverage > 127 * (1 + self.sobelThreshold)) {
        sobelState = SobelStateEntering;
    } else {
        if (sobelState == SobelStateEntering) {
            didEnter = YES;
        }
        
        if (gradientAverage < 127 * (1 - self.sobelThreshold)) {
            sobelState = SobelStateLeaving;
        } else {
            if (sobelState == SobelStateEntering) {
                sobelState = SobelStateInside;
            } else if (sobelState == SobelStateLeaving) {
                sobelState = SobelStateOutside;
            }
        }
    }
    
    return didEnter;
}


- (void)plotInkPointsAtOffset:(float)offset
{
    [self resetSobelState];
    
    for (int y = 0; y < imageHeight; y++) {
        CGPoint currentPoint = CGPointMake(offset * imageWidth, y);
        
        if ([self didEnterInkAtPoint:currentPoint]) {
            [self.delegate plotImagePoint:currentPoint];
        }
    }
}


#pragma mark - 'Public' methods

- (void)locateStaves
{
    int leftOffset = 1;
    int rightOffset = 99;
    BOOL leftSignalFound = NO;
    BOOL rightSignalFound = NO;
    
    while (!leftSignalFound && (leftOffset < 50)) {
        for (int y = 0; y < imageHeight - 1; y++) {
            CGPoint leftPoint = CGPointMake((float)leftOffset / 100 * imageWidth, y);
            
            leftSignalFound = leftSignalFound || [self didEnterInkAtPoint:leftPoint];
        }
        
        if (!leftSignalFound) {
            leftOffset++;
        }
    }
    
    while (!rightSignalFound && (rightOffset > 50)) {
        for (int y = 0; y < imageHeight - 1; y++) {
            CGPoint rightPoint = CGPointMake((float)rightOffset / 100 * imageWidth, y);

            rightSignalFound = rightSignalFound || [self didEnterInkAtPoint:rightPoint];
        }
        
        if (!rightSignalFound) {
            rightOffset--;
        }
    }
    
    if (leftSignalFound && rightSignalFound) {
        int startOffsetLeft = leftOffset + 5;
        int startOffsetRight = rightOffset - 5;
        int offsetIncrement = (startOffsetRight - startOffsetLeft) / 3;
        
        for (int offset = startOffsetLeft; offset <= startOffsetRight; offset += offsetIncrement) {
            [self.staveLocator setCurrentImageOffset:(float)offset / 100 * imageWidth];
            
            int sampleOrigin = offset;
            int sampleOffset = 0;
            int sign = -1;
            
            while (abs(sampleOffset) <= 10) {
                sampleOrigin += sign * sampleOffset;
                sampleOffset++;
                sign = -sign;
                
                for (int y = 0; y < imageHeight; y++) {
                    CGPoint currentPoint = CGPointMake((float)sampleOrigin / 100 * imageWidth, y);
                    
                    if ([self didEnterInkAtPoint:currentPoint]) {
                        [self.staveLocator processStaveVote:currentPoint];
                        [self.delegate plotImagePoint:currentPoint];
                    }
                }
            }
        }
        
        Stave *firstStave = staveLocator.firstStave;
        NSDictionary *candidateArrays = [firstStave candidateArrays];
        
        NSNumber *x;
        NSMutableArray *candidateArray;
        NSEnumerator *enumerator = [candidateArrays keyEnumerator];
        
        while ((x = [enumerator nextObject])) {
            candidateArray = [candidateArrays objectForKey:x];
            
            for (int i = 0; i < [candidateArray count]; i++) {
                CGPoint candidatePoint = CGPointMake([x intValue], [[candidateArray objectAtIndex:i] intValue]);
                [self.delegate plotImagePoint:candidatePoint withColour:[UIColor greenColor]];
            }
        }
    }
}


- (UIImage *)obtainSobelImage
{
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
    UIImage *theSobelImage = [[UIImage imageWithCGImage:sobelImageCG] retain];
    
    CFRelease(sobelImageCG);
    
    return [theSobelImage autorelease];
}


#pragma mark - Lifecycle & housekeeping

- (id)init
{
    self = [self initWithImage:nil];
    
    return self;
}


- (id)initWithImage:(UIImage *)anImage
{
    self = [super init];
    
    if (self) {
        sobelThreshold = kDefaultThreshold;
        sobelState = SobelStateOutside;
        self.sourceImage = anImage;
        
        StaveLocator *newStaveLocator = [[StaveLocator alloc] initWithImageHeight:imageHeight];
        self.staveLocator = newStaveLocator;
        [newStaveLocator release];
    }
    
    return self;
}


- (void)dealloc
{
    self.sourceImage = nil;
    
    CGContextRelease(sobelContext);
    free(grayscaleArray);
    free(sobelArray);
    
    self.staveLocator = nil;
    
    [super dealloc];
}

@end
