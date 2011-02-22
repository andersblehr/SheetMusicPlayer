//
//  StaveLocator.m
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 30.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StaveLocator.h"
#import "SobelAnalyser.h"
#import "Stave.h"

#define kDefaultSignalThreshold 5
#define kDefaultVotesThreshold 5


@implementation StaveLocator

@synthesize firstStave;


#pragma mark - 'Private' methods

- (BOOL)detectsMinimumSignal
{
    BOOL detectedSignalLeft = minimumSignalDetected;
    BOOL detectedSignalRight = minimumSignalDetected;
    
    while ((!detectedSignalLeft || !detectedSignalRight) && xSignalLeft < 50 && xSignalRight > 50) {
        int signalCountLeft = 0;
        int signalCountRight = 0;
        
        for (int y = 0; y < imageHeight - 1; y++) {
            if (!detectedSignalLeft) {
                CGPoint point1 = CGPointMake((float) xSignalLeft      / 100 * imageWidth, y);
                CGPoint point2 = CGPointMake((float)(xSignalLeft + 1) / 100 * imageWidth, y);
                
                if ([sobelAnalyser didEnterInkFromTopAtPoint:point1] && [sobelAnalyser didEnterInkFromTopAtPoint:point2]) {
                    signalCountLeft++;
                    
                    detectedSignalLeft = (signalCountLeft == signalThreshold);
                }
            }
            
            if (!detectedSignalRight) {
                CGPoint point1 = CGPointMake((float) xSignalRight      / 100 * imageWidth, y);
                CGPoint point2 = CGPointMake((float)(xSignalRight - 1) / 100 * imageWidth, y);
                
                if ([sobelAnalyser didEnterInkFromTopAtPoint:point1] && [sobelAnalyser didEnterInkFromTopAtPoint:point2]) {
                    signalCountRight++;
                    
                    detectedSignalRight = (signalCountRight == signalThreshold);
                }
            }
        }
        
        if (!detectedSignalLeft) {
            xSignalLeft++;
        }
        
        if (!detectedSignalRight) {
            xSignalRight--;
        }
    }
    
    minimumSignalDetected = (detectedSignalLeft && detectedSignalRight);
    return minimumSignalDetected;
}


- (void)collectLineVotes
{
    int startOffsetLeft = xSignalLeft + 5;
    int startOffsetRight = xSignalRight - 4;
    int offsetIncrement = (startOffsetRight - startOffsetLeft) / 3;
    
    for (int offset = startOffsetLeft; offset <= startOffsetRight; offset += offsetIncrement) {
        currentImageOffset = (float)offset / 100 * imageWidth;
        
        unsigned char *votesArray = malloc(imageHeight);
        memset(votesArray, 0, imageHeight);
        
        NSNumber *imageOffset = [NSNumber numberWithInt:currentImageOffset];
        [pointArrays setObject:[NSValue valueWithPointer:votesArray] forKey:imageOffset];
        
        int sampleOrigin = offset;
        int sampleOffset = 0;
        int sign = -1;
        
        while (abs(sampleOffset) <= 10) {
            sampleOrigin += sign * sampleOffset;
            sampleOffset++;
            sign = -sign;
            
            for (int y = 0; y < imageHeight; y++) {
                CGPoint point = CGPointMake((float) sampleOrigin      / 100 * imageWidth, y);
                
                if ([sobelAnalyser didEnterInkFromTopAtPoint:point]) {
                    votesArray[y]++;
                    [sobelAnalyser.delegate plotImagePoint:point];
                }
            }
        }
    }
}


- (void)extractPointsWithMostVotes
{
    NSNumber *x;
    NSEnumerator *enumerator = [pointArrays keyEnumerator];
    
    while ((x = [enumerator nextObject])) {
        unsigned char *pointArray = [[pointArrays objectForKey:x] pointerValue];
        
        NSMutableArray *candidateArray = [candidateArrays objectForKey:x];
        
        if (!candidateArray) {
            candidateArray = [[NSMutableArray alloc] init];
            
            [candidateArrays setObject:candidateArray forKey:x];
            
            for (int y = 1; y < imageHeight - 1; y++) {
                if (pointArray[y - 1] + pointArray[y] + pointArray[y + 1] >= votesThreshold) {
                    [sobelAnalyser.delegate plotImagePoint:CGPointMake([x intValue], y) withColour:[UIColor greenColor]];
                    [candidateArray addObject:[NSNumber numberWithInt:y]];
                    y += 3;
                }
            }
            
            [candidateArray release];
        }
    }
}


#pragma mark - 'Public' methods

- (BOOL)imageContainsStaves
{
    return [self detectsMinimumSignal];
}


- (void)locateStaves
{
    if ([self detectsMinimumSignal]) {
        [self collectLineVotes];
        [self extractPointsWithMostVotes];
    }
}


#pragma mark - Lifecycle & housekeeping

- (id)initWithSobelAnalyser:(SobelAnalyser *)analyser
{
    self = [super init];
    
    if (self && analyser) {
        sobelAnalyser = analyser;
        
        imageWidth = sobelAnalyser.imageWidth;
        imageHeight = sobelAnalyser.imageHeight;
        currentImageOffset = 0;
        
        xSignalLeft = 1;
        xSignalRight = 99;
        signalThreshold = kDefaultSignalThreshold;
        votesThreshold = kDefaultVotesThreshold;
        minimumSignalDetected = NO;
        
        pointArrays = [[NSMutableDictionary alloc] init];
        candidateArrays = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}


- (void)dealloc
{
    [firstStave release];
    
    NSNumber *x;
    NSEnumerator *enumerator = [pointArrays keyEnumerator];
    
    while ((x = [enumerator nextObject])) {
        unsigned char *pointArray = [[pointArrays objectForKey:x] pointerValue];
        free(pointArray);
    }
    
    [pointArrays release];
    [candidateArrays release];
    
    [super dealloc];
}

@end
