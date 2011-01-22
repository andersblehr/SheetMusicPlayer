//
//  SheetMusicPlayerAppDelegate.m
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 16.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SheetMusicPlayerAppDelegate.h"
#import "MainViewController.h"

@implementation SheetMusicPlayerAppDelegate


@synthesize window;
@synthesize navigationController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [window addSubview:navigationController.view];
    [window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Save data if appropriate.
}

- (void)dealloc {
    [navigationController release];
    [window release];
    
    [super dealloc];
}

@end
