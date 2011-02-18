//
//  OverlayView.h
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 28.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageAnalyser.h"


@interface OverlayView : UIView <ImageAnalyserDelegate> {
@private
    float scaleFactor;
    float zoomScale;
    CGPoint defaultOrigin;
    CGPoint contentOffset;
    
    NSMutableDictionary *plotPointsWithColour;
}

@property (nonatomic, assign) float zoomScale;
@property (nonatomic, assign) CGPoint contentOffset;
@property (nonatomic, retain) NSMutableDictionary *plotPointsWithColour;

- (void)plotImagePoint:(CGPoint)imagePoint;
- (id)initWithImageView:(UIImageView *)imageView;
@end
