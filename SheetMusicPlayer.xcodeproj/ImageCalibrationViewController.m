//
//  ImageCalibrationViewController.m
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 21.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ImageCalibrationViewController.h"


@implementation ImageCalibrationViewController

@synthesize containerView;
@synthesize originalImageView;
@synthesize binaryImageView;
@synthesize binaryImageScrollView;
@synthesize sourceImage;
@synthesize slider;

#define kDefaultWhiteness 0.2f


#pragma mark - 'Private' methods

- (void)createPixelArrays
{
    CGImageRef sourceImageCG = [sourceImage CGImage];
    
    size_t bitsPerComponent = CGImageGetBitsPerComponent(sourceImageCG);
    size_t sourceWidth = CGImageGetWidth(sourceImageCG);
    size_t sourceHeight = CGImageGetHeight(sourceImageCG);
    CGFloat translationWidth = sourceWidth;   // Defaults, may be altered further down
    CGFloat translationHeight = sourceHeight; // 
    CGFloat rotationRadians = 0;              // 
    
    UIImageOrientation sourceOrientation = [sourceImage imageOrientation];
    
    // Handle UIKit and Quartz's differing coordinate systems
    if (sourceOrientation == UIImageOrientationUp) {
        imageWidth = sourceWidth;        // 
        imageHeight = sourceHeight;      // 
    } else if (sourceOrientation == UIImageOrientationDown) {
        imageWidth = sourceWidth;        // 
        imageHeight = sourceHeight;      // 
        rotationRadians = -M_PI;
    } else if (sourceOrientation == UIImageOrientationRight) {
        imageWidth = sourceHeight;
        imageHeight = sourceWidth;
        translationWidth = -(CGFloat)sourceWidth;
        translationHeight = 0;
        rotationRadians = -M_PI/2;
    } else if (sourceOrientation == UIImageOrientationLeft) {
        imageWidth = sourceHeight;
        imageHeight = sourceWidth;
        translationWidth = 0;
        translationHeight = -(CGFloat)sourceHeight;
        rotationRadians = M_PI/2;
    }
    
    grayscaleArray = malloc(imageWidth * imageHeight);
    binaryArray = malloc(imageWidth * imageHeight);
    
    // Convert to grayscale to preserve space (1 byte/pixel vs 4 for RGB)
    monochromeColourSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef grayscaleContext = CGBitmapContextCreate(grayscaleArray, imageWidth, imageHeight, bitsPerComponent, imageWidth, monochromeColourSpace, kCGImageAlphaNone);
    
    // Rotate & translate Quartz coordinate system to preserve image orientation
    if (sourceOrientation != UIImageOrientationUp) {
        CGContextRotateCTM(grayscaleContext, rotationRadians);
        CGContextTranslateCTM(grayscaleContext, translationWidth, translationHeight);
    }
    
    CGContextDrawImage(grayscaleContext, CGRectMake(0, 0, sourceWidth, sourceHeight), sourceImageCG);
    grayscaleImageCG = CGBitmapContextCreateImage(grayscaleContext);
    CGContextRelease(grayscaleContext);
    
    binaryContext = CGBitmapContextCreate(binaryArray, imageWidth, imageHeight, 8, imageWidth, monochromeColourSpace, kCGImageAlphaNone);
}


- (UIImage *)obtainBinaryImageWithWhiteness:(float)whiteness
{
    if (!grayscaleArray)
        [self createPixelArrays];
    
    unsigned char bwThreshold = (unsigned char)round(whiteness * 255);
/*
    for (int i = 0; i < imageHeight; i += 2) {
        int offset1 = imageWidth * i;
        int offset2 = imageWidth * (i + 1);
        
        for (int j = 0; j < imageWidth; j += 2) {
            unsigned char averageLightness = (grayscaleArray[offset1 + j] + grayscaleArray[offset1 + j + 1] + grayscaleArray[offset2 + j] + grayscaleArray[offset2 + j + 1])/4;

            binaryArray[offset1 + j] = (averageLightness > bwThreshold) ? 255 : 0;
            binaryArray[offset1 + j + 1] = binaryArray[offset1 + j];
            binaryArray[offset2 + j] = binaryArray[offset1 + j];
            binaryArray[offset2 + j + 1] = binaryArray[offset1 + j];
        }
    }
*/    
    for (int i = 0; i < imageWidth * imageHeight; i += 2) {
        binaryArray[i] = (grayscaleArray[i] > bwThreshold) ? 255 : 0;
        binaryArray[i+1] = binaryArray[i];
    }
    
    CGImageRef binaryImageCG = CGBitmapContextCreateImage(binaryContext);
    UIImage *theBinaryImage = [[UIImage imageWithCGImage:binaryImageCG] retain];
    
    CFRelease(binaryImageCG);
    
    return [theBinaryImage autorelease];
}


- (UIImage *)obtainSobelImageWithWhiteness:(float)whiteness
{
    if (!grayscaleArray)
        [self createPixelArrays];
    
    unsigned char bwThreshold = (unsigned char)round(whiteness * 255);
    
    for (int y = 0; y < imageHeight; y++) {
        for (int x = 0; x < imageWidth; x++) {
            if ((y == 0) || (y == imageHeight - 1) || (x == 0) || (x == imageWidth - 1))
                binaryArray[x + imageWidth * y] = 255;
            else {
                int Gx = (    grayscaleArray[(x + 1) + (y - 1) * imageWidth] +
                          2 * grayscaleArray[(x + 1) + (y + 0) * imageWidth] +
                              grayscaleArray[(x + 1) + (y + 1) * imageWidth]) -
                         (    grayscaleArray[(x - 1) + (y - 1) * imageWidth] +
                          2 * grayscaleArray[(x - 1) + (y + 0) * imageWidth] +
                              grayscaleArray[(x - 1) + (y + 1) * imageWidth]);
                int Gy = (    grayscaleArray[(x - 1) + (y - 1) * imageWidth] +
                          2 * grayscaleArray[(x + 0) + (y - 1) * imageWidth] +
                              grayscaleArray[(x + 1) + (y - 1) * imageWidth]) -
                         (    grayscaleArray[(x - 1) + (y + 1) * imageWidth] +
                          2 * grayscaleArray[(x + 0) + (y + 1) * imageWidth] +
                              grayscaleArray[(x + 1) + (y + 1) * imageWidth]);
                
                int G = abs(Gx) + abs(Gy);
                binaryArray[x + imageWidth * y] = (G > bwThreshold) ? 0 : 255;
            }
        }
    }
    
    CGImageRef binaryImageCG = CGBitmapContextCreateImage(binaryContext);
    UIImage *theBinaryImage = [[UIImage imageWithCGImage:binaryImageCG] retain];
    
    CFRelease(binaryImageCG);
    
    return [theBinaryImage autorelease];
}


#pragma mark - Memory management

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        grayscaleArray = nil;
    }
    return self;
}


- (void)dealloc
{
    [self.slider removeFromSuperview];
    [self.binaryImageView removeFromSuperview];
    
    self.binaryImageView = nil;
    self.binaryImageScrollView = nil;
    self.containerView = nil;

    self.sourceImage = nil;

    CGColorSpaceRelease(monochromeColourSpace);
    CGContextRelease(binaryContext);
    CFRelease(grayscaleImageCG);
    free(grayscaleArray);
    free(binaryArray);
    
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
    
    [self.navigationController.navigationBar setTintColor:[UIColor darkGrayColor]];
    [self.navigationController.navigationBar setTranslucent:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];

    UIBarButtonItem *playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playAction:)];
    self.navigationItem.rightBarButtonItem = playButton;
    [playButton release];
    
    self.containerView = [[[UIView alloc] initWithFrame:[self.view frame]] autorelease];
    self.view = containerView;
    
    self.originalImageView = [[UIImageView alloc] initWithFrame:[containerView frame]];
    self.originalImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.originalImageView.image = sourceImage;
    [self.containerView addSubview:originalImageView];

    self.binaryImageScrollView = [[UIScrollView alloc] initWithFrame:[containerView frame]];
    self.binaryImageScrollView.contentSize = containerView.frame.size;
    self.binaryImageScrollView.minimumZoomScale = 1.0f;
    self.binaryImageScrollView.maximumZoomScale = 4.0f;
    self.binaryImageScrollView.clipsToBounds = YES;
    self.binaryImageScrollView.bouncesZoom = NO;
    self.binaryImageScrollView.delegate = self;
    
    UITapGestureRecognizer *doubleTapRecogniser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapAction:)];
    doubleTapRecogniser.numberOfTapsRequired = 2;
    [self.binaryImageScrollView addGestureRecognizer:doubleTapRecogniser];
    
    UITapGestureRecognizer *singleTapRecogniser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapAction:)];
    singleTapRecogniser.numberOfTapsRequired = 1;
    [singleTapRecogniser requireGestureRecognizerToFail:doubleTapRecogniser];
    [self.binaryImageScrollView addGestureRecognizer:singleTapRecogniser];
    
    [doubleTapRecogniser release];    
    [singleTapRecogniser release];
    
    self.binaryImageView = [[UIImageView alloc] initWithFrame:[containerView frame]];
    self.binaryImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.binaryImageScrollView addSubview:binaryImageView];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.binaryImageView.image = [self obtainSobelImageWithWhiteness:kDefaultWhiteness];
    //self.binaryImageView.image = [self obtainBinaryImageWithWhiteness:kDefaultWhiteness];
    [self.containerView insertSubview:binaryImageScrollView belowSubview:originalImageView];
    
    // Animate transition from original to binary image
    if ([[[UIDevice currentDevice] systemVersion] compare:@"4.0"] != NSOrderedAscending) {
        // iOS 4.x
        [UIView animateWithDuration:2.0 animations:^{ self.originalImageView.alpha = 0.0; } completion:^(BOOL finished) {
            [self.originalImageView removeFromSuperview];
            self.originalImageView = nil;
            
            [self.slider setValue:kDefaultWhiteness];
            //[self.slider setHidden:YES];
            [self.containerView addSubview:slider];
            
            //[self.navigationController setNavigationBarHidden:YES animated:YES];
        }];
    } else {
        // iPhoneOS 3.x
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:2.0];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationsEnabled:YES];
        [UIView setAnimationDidStopSelector:@selector(tranisitionToBinaryEnded:)];
        [UIView setAnimationDelegate:self];
        self.originalImageView.alpha = 0.0;
        [UIView commitAnimations];
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
        [self.slider setHidden:NO];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    } else {
        [self.slider setHidden:YES];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    }
}


- (void)doubleTapAction:(UITapGestureRecognizer *)doubleTapRecogniser
{
    if (self.binaryImageScrollView.zoomScale > 1.0f) {
        self.binaryImageScrollView.zoomScale = 1.0f;
    }
}


#pragma mark - UIScrollViewDelegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return binaryImageView;
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


- (void)tranisitionToBinaryEnded:(id)sender
{
    // Only used for iPhoneOS 3.x
    [self.originalImageView removeFromSuperview];
    self.originalImageView = nil;
    
    [self.slider setValue:kDefaultWhiteness];
    [self.slider setHidden:YES];
    [self.containerView addSubview:slider];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}


#pragma mark - IBAction methods

- (IBAction)sliderAction:(id)sender
{
    self.binaryImageView.image = [self obtainSobelImageWithWhiteness:[slider value]];
    //self.binaryImageView.image = [self obtainBinaryImageWithWhiteness:[slider value]];
}

@end
