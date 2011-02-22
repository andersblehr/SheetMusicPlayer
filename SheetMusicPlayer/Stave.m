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

@synthesize nextStave;


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
    }
    
    return self;
}


- (void)dealloc
{
    [super dealloc];
}


@end
