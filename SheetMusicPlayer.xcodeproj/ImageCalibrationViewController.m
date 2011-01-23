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
@synthesize sourceImage;
@synthesize binaryImage;
@synthesize slider;

#define kDefaultWhiteness 0.3f


#pragma mark - 'Private' methods

- (UIImage *)obtainBinaryImageWithWhiteness:(float)whiteness
{
    CGColorSpaceRef monochromeColourSpace = CGColorSpaceCreateDeviceGray();
    
    if (!grayscaleArray) {
        CGImageRef sourceImageCG = [sourceImage CGImage];
        
        size_t bitsPerComponent = CGImageGetBitsPerComponent(sourceImageCG);
        size_t sourceWidth = CGImageGetWidth(sourceImageCG);
        size_t sourceHeight = CGImageGetHeight(sourceImageCG);
        size_t imageWidth = sourceWidth;        // 
        size_t imageHeight = sourceHeight;      // 
        CGFloat translationWidth = sourceWidth;   // Defaults, may be altered further down
        CGFloat translationHeight = sourceHeight; // 
        CGFloat rotationRadians = 0;              // 
        
        UIImageOrientation sourceOrientation = [sourceImage imageOrientation];
        
        // Handle UIKit and Quartz's differing coordinate systems
        if (sourceOrientation == UIImageOrientationUp) {
            // Do nothing
        } else if (sourceOrientation == UIImageOrientationDown) {
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
        CGContextRef grayscaleContext = CGBitmapContextCreate(grayscaleArray, imageWidth, imageHeight, bitsPerComponent, imageWidth, monochromeColourSpace, kCGImageAlphaNone);
        
        // Rotate & translate Quartz coordinate system to preserve image orientation
        if (sourceOrientation != UIImageOrientationUp) {
            CGContextRotateCTM(grayscaleContext, rotationRadians);
            CGContextTranslateCTM(grayscaleContext, translationWidth, translationHeight);
        }
        
        CGContextDrawImage(grayscaleContext, CGRectMake(0, 0, sourceWidth, sourceHeight), sourceImageCG);
        grayscaleImageCG = CGBitmapContextCreateImage(grayscaleContext);
        CGContextRelease(grayscaleContext);
    }
    
    size_t imageWidth = CGImageGetWidth(grayscaleImageCG);
    size_t imageHeight = CGImageGetHeight(grayscaleImageCG);
    
    unsigned char bwThreshold = (unsigned char)round(whiteness * 255);
    
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
/*    
    for (int i = 0; i < imageWidth * imageHeight; i += 2) {
        binaryArray[i] = (grayscaleArray[i] > bwThreshold) ? 255 : 0;
        binaryArray[i+1] = binaryArray[i];
    }
*/    
    CGContextRef binaryContext = CGBitmapContextCreate(binaryArray, imageWidth, imageHeight, 8, imageWidth, monochromeColourSpace, kCGImageAlphaNone);
    CGImageRef binaryImageCG = CGBitmapContextCreateImage(binaryContext);
    UIImage *theBinaryImage = [[UIImage imageWithCGImage:binaryImageCG] retain];
    
    CGColorSpaceRelease(monochromeColourSpace);
    CGContextRelease(binaryContext);
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
    [self.containerView removeFromSuperview];
    
    self.binaryImageView = nil;
    self.containerView = nil;

    self.sourceImage = nil;
    self.binaryImage = nil;

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
    
    [self.slider setHidden:YES];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];

    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playAction:)];
    self.navigationItem.rightBarButtonItem = nextButton;
    [nextButton release];
    
    [self.navigationController.navigationBar setTintColor:[UIColor darkGrayColor]];
    [self.navigationController.navigationBar setTranslucent:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];

    self.containerView = [[[UIView alloc] initWithFrame:[self.view frame]] autorelease];
    [self.view addSubview:containerView];
    
    self.originalImageView = [[UIImageView alloc] initWithFrame:[containerView frame]];
    self.originalImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.originalImageView.image = sourceImage;
    [self.containerView addSubview:originalImageView];

    self.binaryImage = [self obtainBinaryImageWithWhiteness:kDefaultWhiteness];
    self.binaryImageView = [[UIImageView alloc] initWithFrame:[containerView frame]];
    self.binaryImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.binaryImageView.image = binaryImage;
    [self.containerView insertSubview:binaryImageView belowSubview:originalImageView];

    // Animate transition from original to binary image
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:2];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationsEnabled:YES];
    [UIView setAnimationDidStopSelector:@selector(tranisitionToBinaryEnded)];
    [UIView setAnimationDelegate:self];
    self.originalImageView.alpha = 0;
    [UIView commitAnimations];
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


#pragma mark - Selector implementations

- (void)cancelAction:(id)sender
{
    [self.slider setHidden:YES];

    [self.navigationController popViewControllerAnimated:YES];
}


- (void)playAction:(id)sender
{

}


- (void)tranisitionToBinaryEnded
{
    [self.originalImageView removeFromSuperview];
    self.originalImageView = nil;
    
    [self.slider setValue:kDefaultWhiteness];
    [self.slider setHidden:NO];
    [self.containerView addSubview:slider];
}


#pragma mark - IBAction methods

- (IBAction)sliderAction:(id)sender
{
    self.binaryImage = [self obtainBinaryImageWithWhiteness:[slider value]];
    self.binaryImageView.image = binaryImage;
    
    [self.binaryImageView setNeedsDisplay];
}

@end
