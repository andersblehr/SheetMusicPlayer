//
//  MusicManager.h
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 30.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StaveLocator : NSObject {
@private
    NSMutableArray *candidateStavePoints;
    NSMutableArray *identifiedStavePoints;
    float mostLikelyStaveInterval;
    float lessLikelyStaveInterval;
    int staveCount;
}

- (void)assessCandidateStaveLine:(CGPoint)point;
@end
