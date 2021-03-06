    //
//  Stave.h
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 09.02.11.
//  Copyright 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SobelAnalyser.h"

@interface Stave : NSObject {
@private
    CGPoint topLineLeft;
    CGPoint topLineCentre;
    CGPoint topLineRight;
    CGPoint bottomLineLeft;
    CGPoint bottomLineCentre;
    CGPoint bottomLineRight;
    
    int lineSpacingLeft;
    int lineSpacingCentre;
    int lineSpacingRight;
    
    SobelAnalyser *sobelAnalyser;
    Stave *nextStave;
}

@property (nonatomic, assign) CGPoint topLineLeft;
@property (nonatomic, assign) CGPoint topLineCentre;
@property (nonatomic, assign) CGPoint topLineRight;
@property (nonatomic, assign) CGPoint bottomLineLeft;
@property (nonatomic, assign) CGPoint bottomLineCentre;
@property (nonatomic, assign) CGPoint bottomLineRight;

@property (nonatomic, assign) int lineSpacingLeft;
@property (nonatomic, assign) int lineSpacingCentre;
@property (nonatomic, assign) int lineSpacingRight;

@property (nonatomic, retain) Stave *nextStave;

- (void)evaluateCandidateStaveLine:(NSArray *)staveLinePoints;
- (id)initWithSobelAnalyser:(SobelAnalyser *)analyser;

@end
