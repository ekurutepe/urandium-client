//
//  FJPhudgeFacebookInterface.h
//  Phudge
//
//  Created by Engin Kurutepe on 26.02.12.
//  Copyright (c) 2012 Fifteen Jugglers Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Facebook.h"

#define kFBAPPID @"XXXXXX"

@interface FJPhudgeFacebookInterface : NSObject <FBSessionDelegate, FBRequestDelegate> 

@property (nonatomic, strong) Facebook * facebook;

+(FJPhudgeFacebookInterface*) sharedInterface;

- (void) login;
- (void) postToFeedWithImage:(UIImage*)image andCaption:(NSString*)caption;

@end
