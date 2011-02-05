//
//  ImageCalibrationViewController.m
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 21.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ImageCalibrationViewController.h"
#import "OverlayView.h"
#import "ImageAnalyser.h"


@implementation ImageCalibrationViewController

@dynamic sourceImage;
@synthesize slider;

@synthesize containerView;
@synthesize sourceImageView;
@synthesize sobelImageView;
@synthesize overlayView;
@synthesize overlayImageScrollView;

@synthesize imageAnalyser;


#define kMaxImageDimension 2048.f
#define kDefaultThreshold 0.33f
#define kMaxZoomScale 5.f


#pragma mark - Getters & setters for @dynamic properties

- (void)setSourceImage:(UIImage *)theSourceImage
{
    if (self.imageAnalyser) {
        self.imageAnalyser.sourceImage = theSourceImage;
    } else {
        self.imageAnalyser = [[ImageAnalyser alloc] initWithImage:theSourceImage];
    }
}


- (UIImage *)sourceImage
{
    if (self.imageAnalyser) {
        return self.imageAnalyser.sourceImage;
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
    
    [self.slider setValue:kDefaultThreshold];
    [self.slider setHidden:NO];
    [self.containerView addSubview:slider];
}


#pragma mark - Memory management

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        self.imageAnalyser = nil;
    }
    
    return self;
}


- (void)dealloc
{
    [self.slider removeFromSuperview];
    [self.sobelImageView removeFromSuperview];
    
    self.sobelImageView = nil;
    self.overlayView = nil;
    self.overlayImageScrollView = nil;
    self.containerView = nil;

    self.imageAnalyser = nil;
    
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
    
    self.containerView = [[[UIView alloc] initWithFrame:[self.view frame]] autorelease];
    self.view = containerView;
    
    self.sourceImageView = [[UIImageView alloc] initWithFrame:[containerView frame]];
    self.sourceImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.sourceImageView.backgroundColor = [UIColor blackColor];
    self.sourceImageView.image = imageAnalyser.sourceImage;
    [self.containerView addSubview:sourceImageView];

    self.overlayImageScrollView = [[UIScrollView alloc] initWithFrame:[containerView frame]];
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
    
    self.sobelImageView = [[UIImageView alloc] initWithFrame:[containerView frame]];
    self.sobelImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.sobelImageView.backgroundColor = [UIColor blackColor];
    
    self.sobelImageView.image = [imageAnalyser obtainSobelImage];
    //self.sobelImageView.image = [self obtainSobelImageWithThreshold:kDefaultThreshold];
    [self.overlayImageScrollView addSubview:sobelImageView];
    [self.containerView insertSubview:overlayImageScrollView belowSubview:sourceImageView];
    
    // Animate transition from original to binary image
    if ([[[UIDevice currentDevice] systemVersion] compare:@"4.0"] != NSOrderedAscending) {
        // iOS 4.x
        [UIView animateWithDuration:2.0 animations:^{ self.sourceImageView.alpha = 0.0; } completion:^(BOOL finished) { [self tranisitionToBinaryEnded:nil]; }];
    } else {
        // iPhoneOS 3.x
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:2.0];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationsEnabled:YES];
        [UIView setAnimationDidStopSelector:@selector(tranisitionToBinaryEnded:)];
        [UIView setAnimationDelegate:self];
        self.sourceImageView.alpha = 0.0;
        [UIView commitAnimations];
    }

    self.overlayView = [[OverlayView alloc] initWithImageView:[self sobelImageView]];
    [self.overlayImageScrollView addSubview:overlayView];
    [self.imageAnalyser setDelegate:self.overlayView];
    
    [self.imageAnalyser locateStavesUsingThreshold:kDefaultThreshold];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return ((interfaceOrientation == UIInterfaceOrientationPortrait) || (interfaceOrientation == UIInterfaceOrientationLandscapeLeft));
}


#pragma mark - Gesture handling

- (void)singleTapAction:(UITapGestureRecognizer *)singleTapRecogniser
{
    if ([self.navigationController isNavigationBarHidden]) {
        [self.slider setHidden:NO];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    } else {
        [self.slider setHidden:YES];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
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


#pragma mark - UIScrollViewDelegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return sobelImageView;
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    self.overlayView.zoomScale = scrollView.zoomScale;
    self.overlayView.contentOffset = scrollView.contentOffset;
    
    [self.overlayView setNeedsDisplay];
}


#pragma mark - Selector implementations

- (void)cancelAction:(id)sender
{
    [self.slider setHidden:YES];

    [self.navigationController popViewControllerAnimated:YES];
}


- (void)playAction:(id)sender
{

}


#pragma mark - IBAction methods

- (IBAction)sliderAction:(id)sender
{
    [self.overlayView.plotPoints removeAllObjects];
    [self.imageAnalyser locateStavesUsingThreshold:[slider value]];
}

@end
