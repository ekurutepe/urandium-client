/*
     File: RosyWriterViewController.m
 Abstract: View controller for camera interface
  Version: 1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import <QuartzCore/QuartzCore.h>
#import "RosyWriterViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "AVCamUtilities.h"
//#import "PhotoPreviewViewController.h"
#import "FinalizePhudgeViewController.h"
#import "FJPhudgeServerInterface.h"

#define kTransitionDuration	0.75
#define kUpdateFrequency 20  // Hz
#define kFilteringFactor 0.05
#define kNoReadingValue 999
#define kSecondExposureOpacity 0.5

static inline double radians (double degrees) { return degrees * (M_PI / 180); }



@interface RosyWriterViewController ()
- (UIImage *)_mergeTopImage:(UIImage *)topImage bottomImage:(UIImage*) bottomImage;
@end


@implementation RosyWriterViewController

@synthesize previewView;
@synthesize recordButton;
@synthesize stillImageOutput = _stillImageOutput;
@synthesize secondImage = _secondImage;

- (void)updateLabels
{
	if (shouldShowStats) {
		NSString *frameRateString = [NSString stringWithFormat:@"%.2f FPS ", [videoProcessor videoFrameRate]];
 		frameRateLabel.text = frameRateString;
 		[frameRateLabel setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.25]];
 		
 		NSString *dimensionsString = [NSString stringWithFormat:@"%d x %d ", [videoProcessor videoDimensions].width, [videoProcessor videoDimensions].height];
 		dimensionsLabel.text = dimensionsString;
 		[dimensionsLabel setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.25]];
 		
 		CMVideoCodecType type = [videoProcessor videoType];
 		type = OSSwapHostToBigInt32( type );
 		NSString *typeString = [NSString stringWithFormat:@"%.4s ", (char*)&type];
 		typeLabel.text = typeString;
 		[typeLabel setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.25]];
 	}
 	else {
 		frameRateLabel.text = @"";
 		[frameRateLabel setBackgroundColor:[UIColor clearColor]];
 		
 		dimensionsLabel.text = @"";
 		[dimensionsLabel setBackgroundColor:[UIColor clearColor]];
 		
 		typeLabel.text = @"";
 		[typeLabel setBackgroundColor:[UIColor clearColor]];
 	}
}

- (UILabel *)labelWithText:(NSString *)text yPosition:(CGFloat)yPosition
{
	CGFloat labelWidth = 200.0;
	CGFloat labelHeight = 40.0;
	CGFloat xPosition = previewView.bounds.size.width - labelWidth - 10;
	CGRect labelFrame = CGRectMake(xPosition, yPosition, labelWidth, labelHeight);
	UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
	[label setFont:[UIFont systemFontOfSize:36]];
	[label setLineBreakMode:UILineBreakModeWordWrap];
	[label setTextAlignment:UITextAlignmentRight];
	[label setTextColor:[UIColor whiteColor]];
	[label setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.25]];
	[[label layer] setCornerRadius: 4];
	[label setText:text];
	
	return [label autorelease];
}

- (void)applicationDidBecomeActive:(NSNotification*)notifcation
{
	// For performance reasons, we manually pause/resume the session when saving a recording.
	// If we try to resume the session in the background it will fail. Resume the session here as well to ensure we will succeed.
	[videoProcessor resumeCaptureSession];
}

// UIDeviceOrientationDidChangeNotification selector
- (void)deviceOrientationDidChange
{
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
	// Don't update the reference orientation when the device orientation is face up/down or unknown.
	if ( UIDeviceOrientationIsPortrait(orientation) || UIDeviceOrientationIsLandscape(orientation) )
		[videoProcessor setReferenceOrientation:orientation];
}

- (void)viewDidLoad 
{
	[super viewDidLoad];

    // Initialize the class responsible for managing AV capture session and asset writer
    videoProcessor = [[RosyWriterVideoProcessor alloc] init];
	videoProcessor.delegate = self;

	// Keep track of changes to the device orientation so we can update the video processor
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
		
    // Setup and start the capture session
    [videoProcessor setupAndStartCaptureSession];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication]];
    
	oglView = [[RosyWriterPreviewView alloc] initWithFrame:CGRectZero];
	// Our interface is always in portrait.
	oglView.transform = [videoProcessor transformFromCurrentVideoOrientationToOrientation:UIInterfaceOrientationPortrait];
    [previewView addSubview:oglView];
 	CGRect bounds = CGRectZero;
 	bounds.size = [self.previewView convertRect:self.previewView.bounds toView:oglView].size;
 	oglView.bounds = bounds;
    oglView.center = CGPointMake(previewView.bounds.size.width/2.0, previewView.bounds.size.height/2.0);
 	
 	// Set up labels
 	shouldShowStats = YES;
	
	frameRateLabel = [self labelWithText:@"" yPosition: (CGFloat) 10.0];
	[previewView addSubview:frameRateLabel];
	
	dimensionsLabel = [self labelWithText:@"" yPosition: (CGFloat) 54.0];
	[previewView addSubview:dimensionsLabel];
	
	typeLabel = [self labelWithText:@"" yPosition: (CGFloat) 98.0];
	[previewView addSubview:typeLabel];
	
	
	AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
	self.stillImageOutput = stillImageOutput;
	[stillImageOutput release];
	
	
	NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    AVVideoCodecJPEG, AVVideoCodecKey,
                                    nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
	[outputSettings release];
	
	[videoProcessor.captureSession addOutput:self.stillImageOutput];

	
	[motionManager release], motionManager = [[CMMotionManager alloc] init];
	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / kUpdateFrequency)];
	[[UIAccelerometer sharedAccelerometer] setDelegate:self];
	
//	oglView.secondExposure = [UIImage imageNamed:@"s.png"];
	
//	UIImageView *secondExposureView = [[UIImageView alloc] initWithImage:oglView.secondExposure];
//	secondExposureView.alpha = 0.2;
//	[previewView addSubview:secondExposureView];
//	[secondExposureView release];
}

- (void)cleanup
{
	[oglView release];
	oglView = nil;
    
    frameRateLabel = nil;
    dimensionsLabel = nil;
    typeLabel = nil;
	
	[motionManager release], motionManager = nil;
	
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];

	[notificationCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication]];

    // Stop and tear down the capture session
	[videoProcessor stopAndTearDownCaptureSession];
	videoProcessor.delegate = nil;
    [videoProcessor release];
}

- (void)viewDidUnload 
{
	[super viewDidUnload];

	[self cleanup];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
 
	[[FJPhudgeServerInterface sharedInterface] getImageWithBlock:^(UIImage *image) {
		self.secondImage = image;
		NSLog(@"got second image");
	}];
	

    [self.navigationController setNavigationBarHidden:YES animated:animated];

	timer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(updateLabels) userInfo:nil repeats:YES];
	
	oglView.x = 1.0;
	oglView.y = 1.0; 
	oglView.z = 1.0;
//	[motionManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue]
//							   withHandler:^(CMGyroData *gyroData, NSError *error) {
//								   CMRotationRate rotate = gyroData.rotationRate;
//								   
//								   oglView.x = rotate.x;
//								   oglView.y = rotate.y;
//								   oglView.x = rotate.x;
//								   
//								   NSLog(@"%.2f, %.2f, %.2f", oglView.x, oglView.y, oglView.z);
//							   }];
}

- (void)viewDidDisappear:(BOOL)animated
{	
	[super viewDidDisappear:animated];

	[timer invalidate];
	timer = nil;
}

- (void)dealloc 
{
	[self cleanup];

	[super dealloc];
}

- (IBAction)toggleRecording:(id)sender 
{
	[self _captureStillImage];

	return;
	
	// Wait for the recording to start/stop before re-enabling the record button.
	[[self recordButton] setEnabled:NO];
	
	if ( [videoProcessor isRecording] ) {
		// The recordingWill/DidStop delegate methods will fire asynchronously in response to this call
		[videoProcessor stopRecording];
	}
	else {
		// The recordingWill/DidStart delegate methods will fire asynchronously in response to this call
        [videoProcessor startRecording];
	}
}

#pragma mark RosyWriterVideoProcessorDelegate

- (void)recordingWillStart
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[self recordButton] setEnabled:NO];	
		[[self recordButton] setTitle:@"Stop"];

		// Disable the idle timer while we are recording
		[UIApplication sharedApplication].idleTimerDisabled = YES;

		// Make sure we have time to finish saving the movie if the app is backgrounded during recording
		if ([[UIDevice currentDevice] isMultitaskingSupported])
			backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
	});
}

- (void)recordingDidStart
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[self recordButton] setEnabled:YES];
	});
}

- (void)recordingWillStop
{
	dispatch_async(dispatch_get_main_queue(), ^{
		// Disable until saving to the camera roll is complete
		[[self recordButton] setTitle:@"Record"];
		[[self recordButton] setEnabled:NO];
		
		// Pause the capture session so that saving will be as fast as possible.
		// We resume the sesssion in recordingDidStop:
		[videoProcessor pauseCaptureSession];
	});
}

- (void)recordingDidStop
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[self recordButton] setEnabled:YES];
		
		[UIApplication sharedApplication].idleTimerDisabled = NO;

		[videoProcessor resumeCaptureSession];

		if ([[UIDevice currentDevice] isMultitaskingSupported]) {
			[[UIApplication sharedApplication] endBackgroundTask:backgroundRecordingID];
			backgroundRecordingID = UIBackgroundTaskInvalid;
		}
	});
}

- (void)pixelBufferReadyForDisplay:(CVPixelBufferRef)pixelBuffer
{
	// Don't make OpenGLES calls while in the background.
	if ( [UIApplication sharedApplication].applicationState != UIApplicationStateBackground )
		[oglView displayPixelBuffer:pixelBuffer];
}


#pragma mark - Actions


- (void)_captureStillImage
{
    AVCaptureConnection *stillImageConnection = [AVCamUtilities connectionWithMediaType:AVMediaTypeVideo
																		fromConnections:[[self stillImageOutput] connections]];
	//    if ([_stillImageOutput isVideoOrientationSupported])
	//        [_stillImageOutput setVideoOrientation:orientation];
    
    [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:stillImageConnection
                                                         completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, 
																			 NSError *error) 
	 {
		 
		 ALAssetsLibraryWriteImageCompletionBlock completionBlock = ^(NSURL *assetURL, NSError *error) {
			 if (error) {
				 // if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
				 //	[[self delegate] captureManager:self didFailWithError:error];
				 // }
			 }
		 };
		 
		 if (imageDataSampleBuffer != NULL) {
			 
			 
			 
			 NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
//			 ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];

			 UIImage *image = [[UIImage alloc] initWithData:imageData];
			 FinalizePhudgeViewController *previewController = [[FinalizePhudgeViewController alloc] 
                                                                initWithNibName:nil bundle:nil];
             
             previewController.capturedImage = [self _mergeTopImage:self.secondImage
														bottomImage:image];
			 
			 // TODO: refactore downloadedImage to sth like original image
			 previewController.downloadedImage = image;
             
			 [self.navigationController pushViewController:previewController animated:YES];
			 [previewController release];
			 
//			 
//			 [library writeImageToSavedPhotosAlbum:[image CGImage]
//									   orientation:(ALAssetOrientation)[image imageOrientation]
//								   completionBlock:completionBlock];
			 [image release];
			 
//			 [library release];
		 }
		 else
			 completionBlock(nil, error);
		 
		 // if ([[self delegate] respondsToSelector:@selector(captureManagerStillImageCaptured:)]) {
		 //	[[self delegate] captureManagerStillImageCaptured:self];
		 // }
	 }];
}

- (void)_handleShutterButtonTap:(UIButton *)shutterButton
{
	// take photo
	[self _captureStillImage];
	
}


#pragma mark - inclination

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
    // Use a basic low-pass filter to only keep the gravity in the accelerometer values for the X and Y axes
    accelerationX = acceleration.x * kFilteringFactor + accelerationX * (1.0 - kFilteringFactor);
    accelerationY = acceleration.y * kFilteringFactor + accelerationY * (1.0 - kFilteringFactor);
    accelerationZ = acceleration.z * kFilteringFactor + accelerationZ * (1.0 - kFilteringFactor);
    
    // keep the raw reading, to use during calibrations
//	currentRawReading = atan2(accelerationY, accelerationX);
    
	CGFloat k = 50.0;

	if (oglView.x <= 0) directionX = 1.0;
	if (oglView.x >= 1) directionX = - 1.0;
	oglView.x += directionX * ((accelerationX + 1) / 2) / k;
	
	if (oglView.y <= 0) directionY = 1.0;
	if (oglView.y >= 1) directionY = - 1.0;
	oglView.y += directionY * ((accelerationY + 1) / 2) / k;
	
	if (oglView.z <= 0) directionZ = 1.0;
	if (oglView.z >= 1) directionZ = - 1.0;
	oglView.z += directionZ * ((accelerationZ + 1) / 2) / k;
	
//	NSLog(@"%.2f %.2f %.2f (%.2f %.2f %.2f)", oglView.x, oglView.y, oglView.z, accelerationX, accelerationY, accelerationZ);
	
//    float calibratedAngle = [self calibratedAngleFromAngle:currentRawReading];
    
//    [levelView updateToInclinationInRadians:calibratedAngle];
}


#pragma mark - second exposure

- (UIImage *)_mergeTopImage:(UIImage *)topImage bottomImage:(UIImage*) bottomImage
{
	// URL REF: http://iphoneincubator.com/blog/windows-views/image-processing-tricks
	// URL REF: http://stackoverflow.com/questions/1309757/blend-two-uiimages?answertab=active#tab-top
	// URL REF: http://www.waterworld.com.hk/en/blog/uigraphicsbeginimagecontext-and-retina-display
	
	int width = bottomImage.size.width;
	int height = bottomImage.size.height;
	
	CGSize newSize = CGSizeMake(width, height);
	static CGFloat scale = -1.0;
	if (scale<0.0) {
		UIScreen *screen = [UIScreen mainScreen];
		if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 4.0) {
			scale = [screen scale];
		}
		else {
			scale = 0.0;    // Use the standard API
		}
	}
	if (scale>0.0) {
		UIGraphicsBeginImageContextWithOptions(newSize, NO, scale);
	}
	else {
		UIGraphicsBeginImageContext(newSize);
	}
	
	[bottomImage drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
	[topImage drawInRect:CGRectMake(0,0,newSize.width,newSize.height) blendMode:kCGBlendModeNormal alpha:kSecondExposureOpacity];
	
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return newImage;
}

@end
