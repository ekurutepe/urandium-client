//
//  FinalizePhudgeViewController.m
//  Phudge
//
//  Created by Engin Kurutepe on 26.02.12.
//  Copyright (c) 2012 Fifteen Jugglers Software. All rights reserved.
//

#import "FinalizePhudgeViewController.h"



@interface FinalizePhudgeViewController ()

@end

@implementation FinalizePhudgeViewController

@synthesize imageView;
@synthesize capturedImage;
@synthesize downloadedImage;

- (IBAction) saveTapped:(id)sender
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (IBAction) facebookButtonTapped:(id)sender
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (IBAction) twitterButtonTapped:(id)sender
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
