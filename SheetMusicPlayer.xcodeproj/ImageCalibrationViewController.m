//
//  ImageCalibrationViewController.m
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 21.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ImageCalibrationViewController.h"


@implementation ImageCalibrationViewController

@synthesize sourceImage;
@synthesize slider;


#pragma mark - 'Private' methods

- (void)obtainBinaryImage {
    CGImageRef sourceImageCG = [sourceImage CGImage];
    
    size_t bitsPerComponent = CGImageGetBitsPerComponent(sourceImageCG);
    size_t sourceWidth = CGImageGetWidth(sourceImageCG);
    size_t sourceHeight = CGImageGetHeight(sourceImageCG);
    size_t contextWidth = sourceWidth;        // 
    size_t contextHeight = sourceHeight;      // 
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
        contextWidth = sourceHeight;
        contextHeight = sourceWidth;
        translationWidth = -(CGFloat)sourceWidth;
        translationHeight = 0;
        rotationRadians = -M_PI/2;
    } else if (sourceOrientation == UIImageOrientationLeft) {
        contextWidth = sourceHeight;
        contextHeight = sourceWidth;
        translationWidth = 0;
        translationHeight = -(CGFloat)sourceHeight;
        rotationRadians = M_PI/2;
    }
    
    unsigned char *pixelArray = malloc(contextWidth * contextHeight);
    
    // Convert to grayscale to preserve space (1 byte/pixel vs 4 for RGB)
    CGColorSpaceRef monochromeColourSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef grayscaleContext = CGBitmapContextCreate(pixelArray, contextWidth, contextHeight, bitsPerComponent, contextWidth, monochromeColourSpace, kCGImageAlphaNone);
    
    // Rotate & translate Quartz coordinate system to preserve image orientation
    if (sourceOrientation != UIImageOrientationUp) {
        CGContextRotateCTM(grayscaleContext, rotationRadians);
        CGContextTranslateCTM(grayscaleContext, translationWidth, translationHeight);
    }
    
    CGContextDrawImage(grayscaleContext, CGRectMake(0, 0, sourceWidth, sourceHeight), sourceImageCG);
    
    CGImageRef grayscaleImageCG = CGBitmapContextCreateImage(grayscaleContext);
    
    unsigned char bwThreshold = (unsigned char)round([slider value] * 255);
    
    for (int i = 0; i < sourceWidth * sourceHeight; i++) {
        pixelArray[i] = (pixelArray[i] > bwThreshold) ? 255 : 0;
    }
    
    CGImageRef binaryImageCG = CGBitmapContextCreateImage(grayscaleContext);
    binaryImage = [UIImage imageWithCGImage:binaryImageCG];

    CGColorSpaceRelease(monochromeColourSpace);
    CGContextRelease(grayscaleContext);
    CFRelease(grayscaleImageCG); // Releasing CGImage instances created here.
    CFRelease(binaryImageCG);
    free(pixelArray);
}


- (void)dissolveToBinary
{
    CGImageRef sourceImageCG = [sourceImage CGImage];
    
    size_t bitsPerComponent = CGImageGetBitsPerComponent(sourceImageCG);
    size_t bytesPerRow = CGImageGetBytesPerRow(sourceImageCG);
    size_t sourceWidth = CGImageGetWidth(sourceImageCG);
    size_t sourceHeight = CGImageGetHeight(sourceImageCG);

    CGColorSpaceRef colourSpace = CGImageGetColorSpace(sourceImageCG);
    size_t components = CGColorSpaceGetNumberOfComponents(colourSpace);
    
//    CGContextRef bitmapContext = CGBitmapContextCreate(pixelArray, sourceWidth, sourceHeight, bitsPerComponent, bytesPerRow, colourSpace, kCGImageAlphaNone);

}


#pragma mark - Memory management

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        containerView = nil;
        originalImageView = nil;
        binaryImageView = nil;
        sourceImage = nil;
        binaryImage = nil;
    }
    return self;
}


- (void)dealloc
{
    sourceImage = nil;
    binaryImage = nil;
    
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
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];
    
    [self.navigationController.navigationBar setTintColor:[UIColor darkGrayColor]];
    [self.navigationController.navigationBar setTranslucent:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];

    containerView = [[[UIView alloc] initWithFrame:[self.view frame]] autorelease];
    [self.view addSubview:containerView];
    
    [self obtainBinaryImage];
    
    binaryImageView = [[UIImageView alloc] initWithFrame:[containerView frame]];
    originalImageView = [[UIImageView alloc] initWithFrame:[containerView frame]];

    binaryImageView.contentMode = UIViewContentModeScaleAspectFit;
    binaryImageView.image = binaryImage;
    originalImageView.contentMode = UIViewContentModeScaleAspectFit;
    originalImageView.image = sourceImage;
    
    [containerView addSubview:binaryImageView];
    [containerView addSubview:originalImageView];
    
    [self dissolveToBinary];
    
    
    [slider setValue:0.3f];
    [containerView addSubview:slider];
    
    [binaryImageView release];
    [originalImageView release];
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


#pragma mark - Navigation bar actions

- (void)cancel:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - IBAction methods

- (IBAction)sliderAction:(id)sender
{
    
}

@end
