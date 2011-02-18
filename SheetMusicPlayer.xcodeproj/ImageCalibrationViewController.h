//
//  ImageCalibrationViewController.h
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 21.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OverlayView.h"
#import "ImageAnalyser.h"


@interface ImageCalibrationViewController : UIViewController <UIScrollViewDelegate, UIGestureRecognizerDelegate> {
@private
    UISlider *thresholdSlider;
    UISlider *positionSlider;
    UILabel *thresholdLabel;
    UILabel *positionLabel;
    
    UIView *containerView;
    UIImageView *sourceImageView;
    UIImageView *sobelImageView;
    OverlayView *overlayView;
    UIScrollView *overlayImageScrollView;
    
    ImageAnalyser *imageAnalyser;
}

@property (nonatomic, retain) UIImage *sourceImage;
@property (nonatomic, retain) IBOutlet UISlider *thresholdSlider;
@property (nonatomic, retain) IBOutlet UISlider *positionSlider;
@property (nonatomic, retain) IBOutlet UILabel *thresholdLabel;
@property (nonatomic, retain) IBOutlet UILabel *positionLabel;

@property (nonatomic, retain) UIView *containerView;
@property (nonatomic, retain) UIImageView *sourceImageView;
@property (nonatomic, retain) UIImageView *sobelImageView;
@property (nonatomic, retain) OverlayView *overlayView;
@property (nonatomic, retain) UIScrollView *overlayImageScrollView;

@property (nonatomic, retain) ImageAnalyser *imageAnalyser;

- (IBAction)sliderAction:(id)sender;

@end
