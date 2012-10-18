//
//  OverlayView.h
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 28.01.11.
//  Copyright 2011 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SobelAnalyser.h"


@interface OverlayView : UIView <SobelAnalyserDelegate> {
@private
    float scaleFactor;
    CGPoint defaultOrigin;
    
    NSMutableDictionary *plotPointsWithColour;
    NSMutableArray *staveLines;
}

@property (nonatomic, retain) NSMutableDictionary *plotPointsWithColour;

- (id)initWithFrame:(CGRect)frame imageSize:(CGSize)imageSize;

@end
