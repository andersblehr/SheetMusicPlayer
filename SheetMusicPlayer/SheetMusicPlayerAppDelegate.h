//
//  SheetMusicPlayerAppDelegate.h
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 16.01.11.
//  Copyright 2011 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MainViewController;

@interface SheetMusicPlayerAppDelegate : NSObject <UIApplicationDelegate> {
@private
    UINavigationController *navigationController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@end
