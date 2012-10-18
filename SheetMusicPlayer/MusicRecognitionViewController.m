//
//  ImageCalibrationViewController.m
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 21.01.11.
//  Copyright 2011 Rhelba Software. All rights reserved.
//

#import "MusicRecognitionViewController.h"
#import "OverlayView.h"
#import "MusicRecogniser.h"


@implementation MusicRecognitionViewController

@dynamic sourceImage;
@synthesize thresholdSlider;
@synthesize positionSlider;
@synthesize thresholdLabel;
@synthesize positionLabel;

@synthesize containerView;
@synthesize sourceImageView;
@synthesize sobelImageView;
@synthesize overlayView;
@synthesize overlayImageScrollView;

@synthesize musicRecogniser;


#define kDefaultPosition 0.5f
#define kMaxZoomScale 5.f


#pragma mark - Getters & setters for @dynamic properties

- (void)setSourceImage:(UIImage *)sourceImage
{
    if (self.musicRecogniser) {
        self.musicRecogniser.grayscaleImage = sourceImage;
    } else {
        MusicRecogniser *newMusicRecogniser = [[MusicRecogniser alloc] initWithImage:sourceImage];
        self.musicRecogniser = newMusicRecogniser;
        [newMusicRecogniser release];
    }
}


- (UIImage *)sourceImage
{
    if (self.musicRecogniser) {
        return self.musicRecogniser.grayscaleImage;
    } else {
        return nil;
    }
}


#pragma mark - 'Private' methods

- (void)tranisitionToBinaryEnded:(id)sender
{
    [self.sourceImageView removeFromSuperview];
    self.sourceImageView = nil;
    
    [self.navigationController.navigationBar setTintColor:[UIColor darkGrayColor]];
    [self.navigationController.navigationBar setTranslucent:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    [self.thresholdSlider setValue:self.musicRecogniser.sobelThreshold];
    [self.thresholdSlider setHidden:NO];
    [self.thresholdLabel setTextColor:[UIColor whiteColor]];
    [self.thresholdLabel setText:[NSString stringWithFormat:@"%1.2f", self.musicRecogniser.sobelThreshold]];
    [self.thresholdLabel setHidden:NO];
    [self.containerView addSubview:thresholdSlider];
    [self.containerView addSubview:thresholdLabel];
    
    [self.positionSlider setValue:kDefaultPosition];
    [self.positionSlider setHidden:NO];
    [self.positionLabel setTextColor:[UIColor whiteColor]];
    [self.positionLabel setText:[NSString stringWithFormat:@"%1.2f", kDefaultPosition]];
    [self.positionLabel setHidden:NO];
    [self.containerView addSubview:positionSlider];
    [self.containerView addSubview:positionLabel];
}


#pragma mark - Memory management

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        self.musicRecogniser = nil;
    }
    
    return self;
}


- (void)dealloc
{
    [self.thresholdSlider removeFromSuperview];
    [self.thresholdLabel removeFromSuperview];
    [self.positionSlider removeFromSuperview];
    [self.positionLabel removeFromSuperview];
    
    [self.sobelImageView removeFromSuperview];
    
    self.sobelImageView = nil;
    self.overlayView = nil;
    self.overlayImageScrollView = nil;
    self.containerView = nil;
    
    self.musicRecogniser = nil;
    
    [super dealloc];
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    [self.musicRecogniser didReceiveMemoryWarning];
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
	self.title = @"Photo Calibration";
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];
    
    UIBarButtonItem *playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playAction:)];
    self.navigationItem.rightBarButtonItem = playButton;
    [playButton release];
    
    UIView *newContainerView = [[UIView alloc] initWithFrame:[self.view frame]];
    self.containerView = newContainerView;
    [newContainerView release];
    
    UIImageView *newSourceImageView = [[UIImageView alloc] initWithFrame:[self.containerView frame]];
    self.sourceImageView = newSourceImageView;
    [newSourceImageView release];
    
    UIScrollView *newOverlayImageScrollView = [[UIScrollView alloc] initWithFrame:[self.containerView frame]];
    self.overlayImageScrollView = newOverlayImageScrollView;
    [newOverlayImageScrollView release];
    
    self.view = self.containerView;
    
    self.sourceImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.sourceImageView.backgroundColor = [UIColor blackColor];
    self.sourceImageView.image = musicRecogniser.grayscaleImage;
    [self.containerView addSubview:sourceImageView];
    
    self.overlayImageScrollView.contentSize = containerView.frame.size;
    self.overlayImageScrollView.minimumZoomScale = 1.0f;
    self.overlayImageScrollView.maximumZoomScale = kMaxZoomScale;
    self.overlayImageScrollView.clipsToBounds = YES;
    self.overlayImageScrollView.bouncesZoom = NO;
    self.overlayImageScrollView.delegate = self;
    
    UITapGestureRecognizer *doubleTapRecogniser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapAction:)];
    doubleTapRecogniser.numberOfTapsRequired = 2;
    [self.overlayImageScrollView addGestureRecognizer:doubleTapRecogniser];
    
    UITapGestureRecognizer *singleTapRecogniser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapAction:)];
    singleTapRecogniser.numberOfTapsRequired = 1;
    [singleTapRecogniser requireGestureRecognizerToFail:doubleTapRecogniser];
    [self.overlayImageScrollView addGestureRecognizer:singleTapRecogniser];
    
    [doubleTapRecogniser release];    
    [singleTapRecogniser release];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    UIImageView *newSobelImageView = [[UIImageView alloc] initWithFrame:[self.containerView frame]];
    self.sobelImageView = newSobelImageView;
    [newSobelImageView release];
    
    self.sobelImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.sobelImageView.backgroundColor = [UIColor blackColor];
    
    self.sobelImageView.image = musicRecogniser.sobelImage;
    [self.overlayImageScrollView addSubview:sobelImageView];
    [self.containerView insertSubview:overlayImageScrollView belowSubview:sourceImageView];
        
    if ([self.musicRecogniser imageContainsMusic]) {
        // Animate transition from original to binary image
        [UIView animateWithDuration:2.0 animations:^{ self.sourceImageView.alpha = 0.0; } completion:^(BOOL finished) { [self tranisitionToBinaryEnded:self]; }];
        
        OverlayView *newOverlayView = [[OverlayView alloc] initWithFrame:sobelImageView.frame imageSize:sobelImageView.image.size];
        self.overlayView = newOverlayView;
        [newOverlayView release];
        
        //[self.overlayImageScrollView addSubview:self.overlayView];
        [self.sobelImageView addSubview:self.overlayView];
        [self.musicRecogniser.sobelAnalyser setDelegate:self.overlayView];
        
        [self.musicRecogniser plotMusic];
    } else {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Cannot find music" message:@"There appears to be no music in this photo. Please take or pick another photo, and remember to use flash if your device supports it." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
        [alert show];
    }
}


- (void)viewDidUnload
{
    [super viewDidUnload];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Gesture handling

- (void)singleTapAction:(UITapGestureRecognizer *)singleTapRecogniser
{
    if ([self.navigationController isNavigationBarHidden]) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        [self.thresholdSlider setHidden:NO];
        [self.thresholdLabel setHidden:NO];
        [self.positionSlider setHidden:NO];
        [self.positionLabel setHidden:NO];
    } else {
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        [self.thresholdSlider setHidden:YES];
        [self.thresholdLabel setHidden:YES];
        [self.positionSlider setHidden:YES];
        [self.positionLabel setHidden:YES];
    }
}


- (void)doubleTapAction:(UITapGestureRecognizer *)doubleTapRecogniser
{
    if (self.overlayImageScrollView.zoomScale > 1.0f) {
        self.overlayImageScrollView.zoomScale = 1.0f;
    } else {
        self.overlayImageScrollView.zoomScale = kMaxZoomScale;
    }
}


#pragma mark - Selector implementations

- (void)cancelAction:(id)sender
{
    [self.thresholdSlider setHidden:YES];
    [self.thresholdLabel setHidden:YES];;
    [self.positionSlider setHidden:YES];
    [self.positionLabel setHidden:YES];
    
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)playAction:(id)sender
{
    //[self.overlayView.plotPointsWithColour removeAllObjects];
    //[self.musicRecogniser locateStaves];
}


#pragma mark - IBAction methods

- (IBAction)sliderAction:(id)sender
{
    [self.thresholdLabel setText:[NSString stringWithFormat:@"%1.2f", [thresholdSlider value]]];
    [self.positionLabel setText:[NSString stringWithFormat:@"%1.2f", [positionSlider value]]];
    
    //[self.overlayView.plotPointsWithColour removeAllObjects];
    [self.musicRecogniser setSobelThreshold:[thresholdSlider value]];
}


#pragma mark - UIScrollViewDelegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return sobelImageView;
}


#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self cancelAction:self];
}

@end
