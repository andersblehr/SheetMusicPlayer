//
//  ImageCalibrationViewController.h
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 21.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ImageCalibrationViewController : UIViewController {
@private
    UIView *containerView;
    UIImageView *originalImageView;
    UIImageView *binaryImageView;
    UIImage *sourceImage;
    UIImage *binaryImage;
    UISlider *slider;

    CGImageRef grayscaleImageCG;
    unsigned char *grayscaleArray;
    unsigned char *binaryArray;
}

@property (nonatomic, retain) UIView *containerView;
@property (nonatomic, retain) UIImageView *originalImageView;
@property (nonatomic, retain) UIImageView *binaryImageView;
@property (nonatomic, retain) UIImage *sourceImage;
@property (nonatomic, retain) UIImage *binaryImage;
@property (nonatomic, retain) IBOutlet UISlider *slider;

- (IBAction)sliderAction:(id)sender;

@end
