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
    
    unsigned char *pixelArray;
}

@property (nonatomic, retain) UIImage *sourceImage;
@property (nonatomic, retain) IBOutlet UISlider *slider;

- (IBAction)sliderAction:(id)sender;

@end
