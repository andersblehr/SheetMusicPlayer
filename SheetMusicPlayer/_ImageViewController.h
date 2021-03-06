//
//  ImageViewController.h
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 21.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ImageViewController : UIViewController {
@private
    UIImage *originalImage;
    UIImage *binaryImage;
    UIImageView *originalImageView;
    UIImageView *binaryImageView;
}

@property (nonatomic, retain) UIImage * originalImage;

@end
