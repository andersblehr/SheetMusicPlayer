//
//  StaveLocator.m
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 30.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StaveLocator.h"
#import "Stave.h"


@implementation StaveLocator

@synthesize currentImageOffset;
@dynamic firstStave;


#pragma mark - Getters & setters for @dynamic properties

- (Stave *)firstStave
{
    if (!firstStave) {
        firstStave = [[Stave alloc] initWithImageHeight:imageHeight];

        NSNumber *x;
        NSEnumerator *enumerator = [pointArrays keyEnumerator];
        
        while ((x = [enumerator nextObject])) {
            unsigned char *pointArray = [[pointArrays objectForKey:x] pointerValue];
            
            [firstStave setCandidateArray:pointArray forX:x];
        }
    }
    
    return firstStave;
}


#pragma mark - 'Public' methods

- (void)processStaveVote:(CGPoint)point;
{
    NSNumber *imageOffset = [NSNumber numberWithInt:currentImageOffset];
    unsigned char *votesArray = [[pointArrays objectForKey:imageOffset] pointerValue];
    
    if (!votesArray) {
        votesArray = malloc(imageHeight);
        memset(votesArray, 0, imageHeight);
        
        [pointArrays setObject:[NSValue valueWithPointer:votesArray] forKey:imageOffset];
    }
    
    votesArray[(int)point.y]++;
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
        currentImageOffset = 0;
        
        pointArrays = [[NSMutableDictionary alloc] init];
        firstStave = nil;
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
    
    [super dealloc];
}

@end
