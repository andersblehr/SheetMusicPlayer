//
//  StaveLocator.h
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 30.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SobelAnalyser.h"
#import "Stave.h"

@interface StaveLocator : NSObject {
@private
    SobelAnalyser *sobelAnalyser;
    
    size_t imageWidth;
    size_t imageHeight;
    size_t currentImageOffset;
    
    int xSignalLeft;
    int xSignalRight;
    int signalThreshold;
    int votesThreshold;
    BOOL minimumSignalDetected;
    
    NSMutableDictionary *pointArrays;
    NSMutableDictionary *candidateArrays;
    Stave *firstStave;
}

@property (nonatomic, retain) Stave *firstStave;

- (BOOL)imageContainsStaves;
- (void)locateStaves;
- (id)initWithSobelAnalyser:(SobelAnalyser *)analyser;

@end
