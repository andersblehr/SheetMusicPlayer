//
//  StaveLocator.h
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 30.01.11.
//  Copyright 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SobelAnalyser.h"
#import "Stave.h"

@interface StaveLocator : NSObject {
@private
    SobelAnalyser *sobelAnalyser;
    
    size_t imageWidth;
    size_t imageHeight;
    
    int currentImageOffset;
    int xOffsetPctLeft;
    int xOffsetPctRight;
    int signalThreshold;
    int votesThreshold;
    BOOL minimumSignalDetected;
    
    NSMutableDictionary *pointArrays;
    NSMutableDictionary *candidateArrays;
    NSMutableArray *alignedPoints;
    NSMutableSet *processedPoints;
    CGPoint alignmentPoint;
    
    Stave *firstStave;
    Stave *currentStave;
}

@property (nonatomic, retain) Stave *firstStave;

- (BOOL)imageContainsStaves;
- (void)locateStaves;
- (Stave *)nextStave;
- (id)initWithSobelAnalyser:(SobelAnalyser *)analyser;

@end
