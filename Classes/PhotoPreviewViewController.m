//
//  PhotoPreviewViewController.m
//  Phudge
//
//  Created by Matteo Caldari on 26/02/2012.
//  Copyright (c) 2012 Matteo Caldari. All rights reserved.
//

#import "PhotoPreviewViewController.h"

@implementation PhotoPreviewViewController

@synthesize image = _image;
@synthesize imageView = _imageView;

- (id)initWithImage:(UIImage *)image
{
	self = [super initWithNibName:@"PhotoPreviewViewController" bundle:nil];
	if (self) {
		self.image = image;
	}
	
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
	self.image = nil;
	[super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	
	self.imageView.image = self.image;
	
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

#pragma mark - Accessors

- (void)setImage:(UIImage *)image
{
	if (image != _image) {
		[_image release];
		_image = [image retain];
	}
	
	if ([self isViewLoaded]) {
		self.imageView.image = image;
	}
}

@end
