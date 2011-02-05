//
//  ImageViewController.m
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 21.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ImageViewController.h"


@implementation ImageViewController

@synthesize originalImage;


#pragma mark - 'Private' methods

- (UIImage *)convertToBinary:(UIImage *)sourceImage {
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
    
    for (int i = 0; i < sourceWidth * sourceHeight; i++) {
        pixelArray[i] = ((float)pixelArray[i]/255 > 0.3) ? 255 : 0;
    }
    
    CGImageRef binaryImageCG = CGBitmapContextCreateImage(grayscaleContext);
    
    CGColorSpaceRelease(monochromeColourSpace);
    CGContextRelease(grayscaleContext);
    free(pixelArray);
    
    return [UIImage imageWithCGImage:binaryImageCG];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        originalImage = nil;
        binaryImage = nil;
        originalImageView = nil;
        binaryImageView = nil;
    }
    return self;
}

- (void)dealloc
{
    [originalImage release];
    [originalImageView release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)loadView
{
}


- (void)viewWillAppear:(BOOL)animated
{
	self.title = @"Photo Calibration";
    
/*    [super viewWillAppear:animated];
    
    originalImageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    originalImageView.contentMode = UIViewContentModeScaleAspectFit;
    originalImageView.image = originalImage;
    
    binaryImage = [self convertToBinary:originalImage];
    binaryImageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    binaryImageView.contentMode = UIViewContentModeScaleAspectFit;
    binaryImageView.backgroundColor = [UIColor blackColor];
    binaryImageView.image = binaryImage;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    self.view = binaryImageView;
*/    
//    [self.view addSubview:binaryImageView];
//    [self.view addSubview:originalImageView];
    
//    [self.view bringSubviewToFront:binaryImageView];
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

#pragma mark - Navigation bar actions

- (void)cancel:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
