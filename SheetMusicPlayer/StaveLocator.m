//
//  StaveLocator.m
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 30.01.11.
//  Copyright 2011 Rhelba Software. All rights reserved.
//

#import "StaveLocator.h"
#import "SobelAnalyser.h"
#import "Stave.h"

#define kDefaultSignalThreshold 5
#define kDefaultVotesThreshold 5


@implementation StaveLocator

@synthesize firstStave;

#pragma mark - Stave access

- (Stave *)nextStave
{
    Stave *nextStave;
    
    if (currentStave) {
        nextStave = currentStave.nextStave;
    } else {
        nextStave = firstStave;
    }
    
    currentStave = nextStave;
    
    return nextStave;
}


#pragma mark - Detect staves and assemble candidate stave line points

- (BOOL)detectsMinimumSignal
{
    BOOL detectedSignalLeft = minimumSignalDetected;
    BOOL detectedSignalRight = minimumSignalDetected;
    
    while ((!detectedSignalLeft || !detectedSignalRight) && xOffsetPctLeft < 50 && xOffsetPctRight > 50) {
        int signalCountLeft = 0;
        int signalCountRight = 0;
        
        int xOffsetLeft = (float)xOffsetPctLeft / 100 * imageWidth;
        int xOffsetLeftPlusOne = (float)(xOffsetPctLeft + 1) / 100 * imageWidth;
        int xOffsetRight = (float)xOffsetPctRight / 100 * imageWidth;
        int xOffsetRightMinusOne = (float)(xOffsetPctRight - 1) / 100 * imageWidth;
        
        for (int y = 0; y < imageHeight; y++) {
            if (!detectedSignalLeft) {
                CGPoint point1 = CGPointMake(xOffsetLeft, y);
                CGPoint point2 = CGPointMake(xOffsetLeftPlusOne, y);
                
                if ([sobelAnalyser didEnterInkFromTopAtPoint:point1] && [sobelAnalyser didEnterInkFromTopAtPoint:point2]) {
                    signalCountLeft++;
                    
                    detectedSignalLeft = (signalCountLeft == signalThreshold);
                }
            }
            
            if (!detectedSignalRight) {
                CGPoint point1 = CGPointMake(xOffsetRight, y);
                CGPoint point2 = CGPointMake(xOffsetRightMinusOne, y);
                
                if ([sobelAnalyser didEnterInkFromTopAtPoint:point1] && [sobelAnalyser didEnterInkFromTopAtPoint:point2]) {
                    signalCountRight++;
                    
                    detectedSignalRight = (signalCountRight == signalThreshold);
                }
            }
        }
        
        if (!detectedSignalLeft) {
            xOffsetPctLeft++;
        }
        
        if (!detectedSignalRight) {
            xOffsetPctRight--;
        }
    }
    
    minimumSignalDetected = (detectedSignalLeft && detectedSignalRight);
    return minimumSignalDetected;
}


- (void)collectLineVotes
{
    int startOffsetLeft = xOffsetPctLeft + 5;
    int startOffsetRight = xOffsetPctRight - 4;
    int offsetIncrement = (startOffsetRight - startOffsetLeft) / 3;
    
    for (int offset = startOffsetLeft; offset <= startOffsetRight; offset += offsetIncrement) {
        currentImageOffset = (float)offset / 100 * imageWidth;
        
        unsigned char *voteArray = malloc(imageHeight);
        memset(voteArray, 0, imageHeight);
        
        NSNumber *imageOffset = [NSNumber numberWithInt:currentImageOffset];
        [pointArrays setObject:[NSValue valueWithPointer:voteArray] forKey:imageOffset];
        
        int sampleOrigin = offset;
        int sampleOffset = 0;
        int sign = -1;
        
        while (abs(sampleOffset) <= 10) {
            sampleOrigin += sign * sampleOffset;
            sampleOffset++;
            sign = -sign;
            
            for (int y = 0; y < imageHeight; y++) {
                CGPoint point = CGPointMake((float)sampleOrigin / 100 * imageWidth, y);
                
                if ([sobelAnalyser didEnterInkFromTopAtPoint:point]) {
                    voteArray[y]++;
                    
                    [sobelAnalyser.delegate plotImagePoint:point];
                }
            }
        }
    }
}


- (void)identifyCandidatePoints
{
    [candidateArrays removeAllObjects];
    
    NSNumber *x;
    NSEnumerator *enumerator = [pointArrays keyEnumerator];
    
    while ((x = [enumerator nextObject])) {
        NSMutableArray *candidateArray = [[NSMutableArray alloc] init];
        [candidateArrays setObject:candidateArray forKey:x];
        
        unsigned char *pointArray = [[pointArrays objectForKey:x] pointerValue];
        
        for (int y = 1; y < imageHeight - 1; y++) {
            if ((pointArray[y] >= pointArray[y - 1]) && (pointArray[y] >= pointArray[y + 1])) {
                int voteCount = pointArray[y - 1] + pointArray[y] + pointArray[y + 1];
                
                if (voteCount >= votesThreshold) {
                    [candidateArray addObject:[NSNumber numberWithInt:y]];
                    y += 3;
                    
                    [sobelAnalyser.delegate plotImagePoint:CGPointMake([x intValue], y) withColour:[UIColor greenColor]];
                } 
            }
        }
    }
}


#pragma mark - Extrapolate stave locations

- (BOOL)point:(CGPoint)point isAlignedWithPoint:(CGPoint)referencePoint
{
    BOOL isAligned = NO;
    
    if (CGPointEqualToPoint(point, referencePoint)) {
        isAligned = YES;
    } else {
        float verticalDelta = abs(referencePoint.y - point.y);
        float horizontalDelta = abs(referencePoint.x - point.x);
        float ratio = verticalDelta / horizontalDelta;
        
        isAligned = (ratio < 0.01f);
    }
    
    return isAligned;
}


- (BOOL)pointIsAligned:(CGPoint)point
{
    BOOL isAligned = NO;
    
    if (CGPointEqualToPoint(point, alignmentPoint)) {
        isAligned = YES;
    } else {
        if ([alignedPoints count] > 0) {
            for (int i = 0; i < [alignedPoints count]; i++) {
                CGPoint referencePoint = [[alignedPoints objectAtIndex:i] CGPointValue];
                
                isAligned = (isAligned || [self point:point isAlignedWithPoint:referencePoint]);
            }
        } else {
            isAligned = [self point:point isAlignedWithPoint:alignmentPoint];
        }
    }
    
    return isAligned;
}


- (void)evaluateCandidatePoint:(CGPoint)point
{
    NSValue *pointValue = [NSValue valueWithCGPoint:point];

    if (![processedPoints member:pointValue] && (abs((int)point.y) < NSIntegerMax / 2)) {
        if ([alignedPoints count] == 0) {
            [alignedPoints addObject:pointValue];
        } else {
            BOOL pointInserted = NO;
            
            for (int i = 0; (!pointInserted) && (i < [alignedPoints count]); i++) {
                CGPoint arrayPoint = [[alignedPoints objectAtIndex:i] CGPointValue];
                
                if (arrayPoint.x > point.x) {
                    [alignedPoints insertObject:pointValue atIndex:i];
                    pointInserted = YES;
                }
            }
            
            if (!pointInserted) {
                [alignedPoints addObject:pointValue];
            }
        }
        
        [processedPoints addObject:pointValue];
        NSLog(@"Accepted aligned point (%d, %d)", (int)point.x, (int)point.y);
    }
}


- (void)appendExtremityPoints
{
    CGPoint leftPoint = [[alignedPoints objectAtIndex:0] CGPointValue];
    CGPoint rightPoint = [[alignedPoints lastObject] CGPointValue];
    
    int xOffsetLeft = (float)xOffsetPctLeft / 100 * imageWidth;
    int xOffsetRight = (float)xOffsetPctRight / 100 * imageWidth;
    
    float verticalDelta = rightPoint.y - leftPoint.y;
    float horizontalDelta = rightPoint.x - leftPoint.x;
    float slope = verticalDelta / horizontalDelta;
    
    float yAtXLeft = leftPoint.y + (xOffsetLeft - leftPoint.x) * slope;
    float yAtXRight = rightPoint.y + (xOffsetRight - rightPoint.x) * slope;
    
    CGPoint leftmostPoint = CGPointMake(xOffsetLeft, yAtXLeft);
    CGPoint rightmostPoint = CGPointMake(xOffsetRight, yAtXRight);
    
    [alignedPoints insertObject:[NSValue valueWithCGPoint:leftmostPoint] atIndex:0];
    [alignedPoints addObject:[NSValue valueWithCGPoint:rightmostPoint]];
}


- (void)extrapolateStaveLocations
{
    NSMutableArray *xPositions = [NSMutableArray arrayWithArray:[candidateArrays allKeys]];
    [xPositions sortUsingSelector:@selector(compare:)];

    int numberOfXPositions = [xPositions count];
    NSMutableSet *exhaustedPositions = [[NSMutableSet alloc] init];

    int yOffsets[numberOfXPositions];
    memset(yOffsets, 0, sizeof(yOffsets));

    CGPoint candidatePoints[numberOfXPositions];
    int staveLineCount = 0;
    
    while ([exhaustedPositions count] < numberOfXPositions) {
        BOOL candidateStaveLineFound = NO;
        
        while (!candidateStaveLineFound && ([exhaustedPositions count] < numberOfXPositions)) {
            alignmentPoint = CGPointZero;
            CGPoint minPoint = CGPointMake(NSIntegerMax, NSIntegerMax);
            int alignedCount = [alignedPoints count];
            
            for (int i = 0; i < numberOfXPositions; i++) {
                NSNumber *x = [xPositions objectAtIndex:i];
                NSArray *yPositions = [candidateArrays objectForKey:x];
                NSNumber *y;
                
                if (yOffsets[i] < [yPositions count]) {
                    y = [yPositions objectAtIndex:yOffsets[i]];
                } else {
                    y = [NSNumber numberWithInt:NSIntegerMax];
                    [exhaustedPositions addObject:x];
                }

                candidatePoints[i] = CGPointMake([x intValue], [y intValue]);;
                minPoint = ([y intValue] < minPoint.y) ? candidatePoints[i] : minPoint;
                
                NSLog(@"%d [yOffset = %d]: (%d, %d)", i, yOffsets[i], [x intValue], [y intValue]);
            }
            
            for (int i = 0; ![alignedPoints count] && (i < numberOfXPositions); i++) {
                for (int j = 0; ![alignedPoints count] && (j < i); j++) {
                    if ([self point:candidatePoints[i] isAlignedWithPoint:candidatePoints[j]]) {
                        alignmentPoint = candidatePoints[j];
                        
                        [self evaluateCandidatePoint:candidatePoints[j]];
                        [self evaluateCandidatePoint:candidatePoints[i]];
                    }
                }
            }
            
            for (int i = 0; i < numberOfXPositions; i++) {
                if ([self pointIsAligned:candidatePoints[i]]) {
                    [self evaluateCandidatePoint:candidatePoints[i]];
                } else if ([self point:candidatePoints[i] isAlignedWithPoint:minPoint]) {
                    yOffsets[i]++;
                }
            }
            
            if (([alignedPoints count] == alignedCount) && [self pointIsAligned:minPoint]) {
                if (numberOfXPositions - [alignedPoints count] <= 1) {
                    NSLog(@"%s", "*** Committing stave line ***");
                    [self appendExtremityPoints];
                    [currentStave evaluateCandidateStaveLine:alignedPoints];
                    
                    candidateStaveLineFound = YES;
                    staveLineCount++;
                } else {
                    NSLog(@"%s", "*** Resetting data structures ***");
                }
                
                [alignedPoints removeAllObjects];
                
                for (int i = 0; i < numberOfXPositions; i++) {
                    if ([self point:candidatePoints[i] isAlignedWithPoint:minPoint]) {
                        yOffsets[i]++;
                    }
                }
            }
        }
    }
    
    NSLog(@"Committed %d stave lines", staveLineCount);
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
        [self identifyCandidatePoints];
        [self extrapolateStaveLocations];
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
        
        xOffsetPctLeft = 1;
        xOffsetPctRight = 99;
        signalThreshold = kDefaultSignalThreshold;
        votesThreshold = kDefaultVotesThreshold;
        minimumSignalDetected = NO;
        
        pointArrays = [[NSMutableDictionary alloc] init];
        candidateArrays = [[NSMutableDictionary alloc] init];
        alignedPoints = [[NSMutableArray alloc] init];
        processedPoints = [[NSMutableSet alloc] init];
        
        Stave *newStave = [[Stave alloc] initWithSobelAnalyser:sobelAnalyser];
        self.firstStave = newStave;
        
        currentStave = self.firstStave;
    }
    
    return self;
}


- (void)dealloc
{
    self.firstStave = nil;
    
    NSNumber *x;
    NSEnumerator *enumerator = [pointArrays keyEnumerator];
    
    while ((x = [enumerator nextObject])) {
        unsigned char *pointArray = [[pointArrays objectForKey:x] pointerValue];
        free(pointArray);
    }
}

@end
