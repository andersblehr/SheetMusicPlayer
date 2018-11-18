//
//  Stave.m
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 09.02.11.
//  Copyright 2011 Rhelba Software. All rights reserved.
//

#import "Stave.h"


@implementation Stave

@synthesize topLineLeft;
@synthesize topLineCentre;
@synthesize topLineRight;
@synthesize bottomLineLeft;
@synthesize bottomLineCentre;
@synthesize bottomLineRight;

@synthesize lineSpacingLeft;
@synthesize lineSpacingCentre;
@synthesize lineSpacingRight;

@synthesize nextStave;


#pragma mark - 'Public' methods

- (void)evaluateCandidateStaveLine:(NSArray *)staveLinePoints
{
    [sobelAnalyser.delegate plotStaveLine:staveLinePoints];
}


#pragma mark - Lifecycle & housekeeping

- (id)initWithSobelAnalyser:(SobelAnalyser *)analyser
{
    self = [super init];
    
    if (self) {
        sobelAnalyser = analyser;
    }
    
    return self;
}


@end
