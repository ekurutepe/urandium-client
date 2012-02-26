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
@synthesize caption;

- (IBAction) saveTapped:(id)sender
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    UIImageWriteToSavedPhotosAlbum(self.capturedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (IBAction) facebookButtonTapped:(id)sender
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (IBAction) twitterButtonTapped:(id)sender
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)               image: (UIImage *) image
    didFinishSavingWithError: (NSError *) error
                 contextInfo: (void *) contextInfo
{
    if (error) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Phudged the Phudge"
                                                         message:[error localizedFailureReason]
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles: nil];
        [alert show];
        [alert release];
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    
    if (self.capturedImage) {
        self.imageView.image = self.capturedImage;
    }

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
