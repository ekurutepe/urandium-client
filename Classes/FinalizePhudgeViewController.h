//
//  FinalizePhudgeViewController.h
//  Phudge
//
//  Created by Engin Kurutepe on 26.02.12.
//  Copyright (c) 2012 Fifteen Jugglers Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FinalizePhudgeViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UIImageView * imageView;
@property (nonatomic, strong) UIImage * capturedImage;
@property (nonatomic, strong) UIImage * downloadedImage;


- (void)               image: (UIImage *) image
    didFinishSavingWithError: (NSError *) error
                 contextInfo: (void *) contextInfo;

- (IBAction) saveTapped:(id)sender;
- (IBAction) facebookButtonTapped:(id)sender;
- (IBAction) twitterButtonTapped:(id)sender;

@end
