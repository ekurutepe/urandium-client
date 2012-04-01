//
//  FJPhudgeFacebookInterface.m
//  Phudge
//
//  Created by Engin Kurutepe on 26.02.12.
//  Copyright (c) 2012 Fifteen Jugglers Software. All rights reserved.
//

#import "FJPhudgeFacebookInterface.h"



static FJPhudgeFacebookInterface * __sharedInterface = nil;

@implementation FJPhudgeFacebookInterface



+ (FJPhudgeFacebookInterface*)sharedInterface
{
    @synchronized(self)
    {
        if (__sharedInterface == nil)
        {
			__sharedInterface = [[FJPhudgeFacebookInterface alloc] init];
            Facebook * fb = [[Facebook alloc] initWithAppId:kFBAPPID
                                                andDelegate:__sharedInterface];
            __sharedInterface.facebook = fb;            
            
        }
        
    }
    return __sharedInterface;
}


- (void) login
{
    NSArray * permissions =  [NSArray arrayWithObjects: 
                              @"publish_stream",
                              nil];
    
    [[self facebook ] authorize:permissions];    
}

- (void) postToFeedWithImage:(UIImage*)image andCaption:(NSString*)caption
{
    
}


#pragma mark - FBSessionDelegate

- (void)fbDidLogin
{
    NSLog(@"Facebook did log in: %@", [self.facebook accessToken]);




}

- (void) fbDidNotLogin:(BOOL)cancelled 
{
    NSLog(@"fb did not login: %d", cancelled);

}


@end
