//
//  Stave.m
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 09.02.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
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

@synthesize candidateArrays;
@synthesize nextStave;


#pragma mark - 'Public' methods

- (void)setCandidateArray:(unsigned char *)pointArray forX:(NSNumber *)x
{
    NSMutableArray *candidateArray = [candidateArrays objectForKey:x];
    
    if (!candidateArray) {
        candidateArray = [[NSMutableArray alloc] init];
        
        [self.candidateArrays setObject:candidateArray forKey:x];
        [candidateArray release];
    } else {
        [candidateArray removeAllObjects];
    }
    
    for (int y = 1; y < imageHeight - 1; y++) {
        if (pointArray[y - 1] + pointArray[y] + pointArray[y + 1] >= 5) {
            [candidateArray addObject:[NSNumber numberWithInt:y]];
            y += 3;
        }
    }
}


#pragma mark - Lifecycle & housekeeping

- (id)init
{
    self = [self initWithImageHeight:0];
    
    return self;
}


- (id)initWithImageHeight:(int)height
{
    self = [super init];
    
    if (self) {
        imageHeight = height;
        
        NSMutableDictionary *newDictionary = [[NSMutableDictionary alloc] init];
        self.candidateArrays = newDictionary;
        [newDictionary release];
    }
    
    return self;
}


- (void)dealloc
{
    [candidateArrays release];
    
    [super dealloc];
}


@end
