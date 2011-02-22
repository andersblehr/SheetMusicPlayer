//
//  MainViewController.m
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 18.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainViewController.h"
#import "MusicRecognitionViewController.h"

#define kTakePhotoButtonIndex   0
#define kChoosePhotoButtonIndex 1
#define kCancelButtonIndex      2


@implementation MainViewController

@synthesize photoPickerActionSheet;
@synthesize photoPickerController;


#pragma mark - 'Private' methods

- (void)pickPhotoFromSourceType:(UIImagePickerControllerSourceType)sourceType {
    if ([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        photoPickerController = [[UIImagePickerController alloc] init];
        photoPickerController.sourceType = sourceType;
        photoPickerController.delegate = self;
        
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        [self presentModalViewController:photoPickerController animated:YES];
        [photoPickerController release];
    }
}


#pragma mark - IBAction methods

- (IBAction)playTuneAction:(id)sender
{
    
}


- (IBAction)scanTuneAction:(id)sender
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        photoPickerActionSheet = [[UIActionSheet alloc] init];
    
        [photoPickerActionSheet addButtonWithTitle:@"Take Photo"];
        [photoPickerActionSheet addButtonWithTitle:@"Choose from Library"];
        [photoPickerActionSheet addButtonWithTitle:@"Cancel"];
        [photoPickerActionSheet setCancelButtonIndex:kCancelButtonIndex];
    
        [photoPickerActionSheet setDelegate:self];
        [photoPickerActionSheet showInView:[self view]];
    } else {
        [self pickPhotoFromSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }
}


#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet == photoPickerActionSheet ) {
        if (buttonIndex == kTakePhotoButtonIndex) {
            [self pickPhotoFromSourceType:UIImagePickerControllerSourceTypeCamera];
        } else if (buttonIndex == kChoosePhotoButtonIndex) {
            [self pickPhotoFromSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        }
        
        [photoPickerActionSheet release];
    }
}


#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissModalViewControllerAnimated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    MusicRecognitionViewController *newMusicRecognitionViewController = [[MusicRecognitionViewController alloc] initWithNibName:@"MusicRecognitionViewController" bundle:[NSBundle mainBundle]];
    newMusicRecognitionViewController.sourceImage = [info valueForKey:UIImagePickerControllerOriginalImage];

    [self.navigationController pushViewController:newMusicRecognitionViewController animated:YES];
    [newMusicRecognitionViewController release];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissModalViewControllerAnimated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}


#pragma mark - Memory management

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        self.photoPickerActionSheet = nil;
        self.photoPickerController = nil;
    }
    
    return self;
}


- (void)dealloc
{
    [super dealloc];
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


@end
