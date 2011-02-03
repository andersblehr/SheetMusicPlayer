//
//  MusicManager.m
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 30.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StaveLocator.h"


@implementation StaveLocator


- (void)submitStavePoints
{
    
}


- (void)assessCandidateStaveLine:(CGPoint)candidate
{
    int candidateCount = [candidateStavePoints count];
    
    if (candidateCount == 0) {
        [candidateStavePoints addObject:[NSValue valueWithCGPoint:candidate]];
    } else if (candidateCount < 5) {
        float thisInterval = candidate.y - [[candidateStavePoints lastObject] CGPointValue].y;
        
        if (mostLikelyStaveInterval == 0.f) {
            mostLikelyStaveInterval = thisInterval;
        } else if (0.9 * mostLikelyStaveInterval < thisInterval < 1.1 * mostLikelyStaveInterval) {
            // Interval is same as previous, high probability this is a stave
            [candidateStavePoints addObject:[NSValue valueWithCGPoint:candidate]];
            candidateCount++;
        } else if (1.8 * mostLikelyStaveInterval < thisInterval < 2.2 * mostLikelyStaveInterval) {
            // Interval is twice previous, medium probability we've missed a stave
            if (candidateCount <= 3) {
                // -o---      -o---
                // -o---      -o---
                // -----  OR  -o---
                // -x---      -----
                // -----      -x---
                [candidateStavePoints addObject:[NSValue valueWithCGPoint:CGPointMake(candidate.x, candidate.y - mostLikelyStaveInterval)]];
                [candidateStavePoints addObject:[NSValue valueWithCGPoint:candidate]];
                candidateCount += 2;
            } else {
                // WHAT TO DO NOW?
            }
        } else if (0.45 * mostLikelyStaveInterval < thisInterval < 0.55 * mostLikelyStaveInterval) {
            // Interval is half previous, medium probability we missed a stave last time around
            if (candidateCount == 2) {
                // -o---      -----
                // -----      -o---
                // -o---  OR  -----
                // -x---      -o---
                // -----      -x---
                lessLikelyStaveInterval = mostLikelyStaveInterval;
                mostLikelyStaveInterval = thisInterval;
                [candidateStavePoints insertObject:[NSValue valueWithCGPoint:CGPointMake(candidate.x, candidate.y - lessLikelyStaveInterval)] atIndex:1];
                [candidateStavePoints addObject:[NSValue valueWithCGPoint:candidate]];
                candidateCount += 2;
            } else if (candidateCount == 3) {
                // -o---
                // -----
                // -o---
                // -----
                // -o---
                //  x
            } else {
                // WHAT TO DO NOW?
            }
        } else {
            // Interval bears no relation with previous
            if (candidateCount == 1) {
                // Previous candidate was a blip
                [candidateStavePoints removeAllObjects];
                [candidateStavePoints addObject:[NSValue valueWithCGPoint:candidate]];
                mostLikelyStaveInterval = 0.f;
            } else if (candidateCount > 2) {
                // HER!!
            }
        }
    }
    
    if (candidateCount == 5) {
        [self submitStavePoints];
        [candidateStavePoints removeAllObjects];
    }
}


- (id)init
{
    self = [super init];
    
    if (self) {
        candidateStavePoints = [[NSMutableArray alloc] initWithCapacity:5];
        identifiedStavePoints = [[NSMutableArray alloc] init];
        mostLikelyStaveInterval = 0.f;
        lessLikelyStaveInterval = 0.f;
    }
    
    return self;
}


- (void)dealloc
{
    [candidateStavePoints release];
    [identifiedStavePoints release];
    
    [super dealloc];
}

@end
