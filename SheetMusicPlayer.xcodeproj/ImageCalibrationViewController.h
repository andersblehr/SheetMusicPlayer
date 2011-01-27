//
//  ImageCalibrationViewController.h
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 21.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ImageCalibrationViewController : UIViewController <UIScrollViewDelegate, UIGestureRecognizerDelegate> {
@private
    UIImage *sourceImage;
    
    UIView *containerView;
    UIImageView *originalImageView;
    UIImageView *binaryImageView;
    UIScrollView *binaryImageScrollView;
    UISlider *slider;

    size_t imageWidth;
    size_t imageHeight;
    
    CGColorSpaceRef monochromeColourSpace;
    CGContextRef binaryContext;
    CGImageRef grayscaleImageCG;
    unsigned char *grayscaleArray;
    unsigned char *binaryArray;
}

@property (nonatomic, retain) UIImage *sourceImage;
@property (nonatomic, retain) UIView *containerView;
@property (nonatomic, retain) UIImageView *originalImageView;
@property (nonatomic, retain) UIImageView *binaryImageView;
@property (nonatomic, retain) UIScrollView *binaryImageScrollView;
@property (nonatomic, retain) IBOutlet UISlider *slider;

- (IBAction)sliderAction:(id)sender;

@end
