//
//  MainViewController.h
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 18.01.11.
//  Copyright 2011 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController <UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
@private
    UIActionSheet *photoPickerActionSheet;
    UIImagePickerController *photoPickerController;
}

@property (nonatomic, retain) UIActionSheet *photoPickerActionSheet;
@property (nonatomic, retain) UIImagePickerController *photoPickerController;

- (IBAction)playTuneAction:(id)sender;
- (IBAction)scanTuneAction:(id)sender;

@end
