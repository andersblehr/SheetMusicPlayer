//
//  StaveLocator.h
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 30.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Stave.h"

@interface StaveLocator : NSObject {
@private
    int imageHeight;
    int currentImageOffset;
    
    NSMutableDictionary *pointArrays;
    Stave *firstStave;
}

@property (nonatomic, assign) int currentImageOffset;
@property (nonatomic, retain) Stave *firstStave;

- (void)processStaveVote:(CGPoint)point;
- (id)initWithImageHeight:(int)height;

@end
