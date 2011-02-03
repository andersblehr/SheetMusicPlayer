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
    UIColor *plotColour;
    NSMutableArray *plotPoints;
}

@property (nonatomic, retain) UIColor *plotColour;
@property (nonatomic, retain) NSMutableArray *plotPoints;


- (void)plotImagePoint:(CGPoint)imagePoint;
- (id)initWithImageView:(UIImageView *)imageView;


@end
