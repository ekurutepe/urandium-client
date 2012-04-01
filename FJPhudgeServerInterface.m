//
//  FJPhudgeServerInterface.m
//  urandium-interface
//
//  Created by Engin Kurutepe on 2/26/12.
//  Copyright (c) 2012 Fifteen Jugglers Software. All rights reserved.
//

#import "FJPhudgeServerInterface.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "ASIS3Request.h"
#import "ASIS3ObjectRequest.h"
#import "NSObject+SBJson.h"

static FJPhudgeServerInterface * __sharedInterface = nil;


NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";



@implementation FJPhudgeServerInterface

+(NSString *) genRandStringLength: (int) len {
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%c", [letters characterAtIndex: rand()%[letters length]]];
    }
    
    return randomString;
}

+ (NSString*)base64forData:(NSData*)theData {
    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease] ;
}

+ (FJPhudgeServerInterface*) sharedInterface
{
    if (__sharedInterface == nil) {
        __sharedInterface = [[FJPhudgeServerInterface alloc] init];
    }
    
    return __sharedInterface;
}

- (void) getImageWithBlock:(FJImageAction)finished
{
    NSString * path = [SERVER_URL stringByAppendingString:@"/photo"];
    

    NSURL * url = [NSURL URLWithString:path];
    ASIHTTPRequest * request = [[ASIHTTPRequest alloc] initWithURL:url];
    
    [request setCompletionBlock:^{
        NSString * response = request.responseString;
        
        NSDictionary * responseDict = [response JSONValue];
        
        NSString * imageUrlString = [responseDict valueForKey:@"url"];
        
        NSURL * imageURL = [NSURL URLWithString:imageUrlString];
        ASIHTTPRequest * imageReq = [[ASIHTTPRequest alloc] initWithURL:imageURL];
        
        [imageReq startSynchronous];
        
        if ([imageReq responseStatusCode] == 200) {
            NSData * imageData = [imageReq responseData];
            
            UIImage * image = [UIImage imageWithData:imageData];
            
            if (image) {
                finished(image);
            }
        }
        else {
            finished(nil);
        }
        [imageReq release];
        [request release];
    }];
    
    [request setFailedBlock:^{
        NSLog(@"get photo failed");
        finished(nil);
        [request release];
    }];
    
    [request startAsynchronous];
}


- (void) getStreamWithBlock:(FJArrayAction)finished
{
    NSString * path = [SERVER_URL stringByAppendingString:@"/stream"];
    
    
    NSURL * url = [NSURL URLWithString:path];
    ASIHTTPRequest * request = [[ASIHTTPRequest alloc] initWithURL:url];
    
    [request setCompletionBlock:^{
        NSString * response = request.responseString;
        
        NSArray * responseArray = [response JSONValue];
        
        if ([responseArray isKindOfClass:[NSArray class]]) {

            finished(responseArray);

        }
        else {
            finished(nil);
        }
        [request release];
    }];
    
    [request setFailedBlock:^{
        NSLog(@"get stream failed");
        finished(nil);
        [request release];
    }];
    
    [request startAsynchronous];    
}

- (void) uploadImage:(UIImage*)image withType:(NSString*)type andLocation:(CLLocation*)location
{
    
    [ASIS3Request setSharedSecretAccessKey:@"ipWbVrA3nVz+23bN0vxGCTddIhgZWsoRko9wJJKn"];
    [ASIS3Request setSharedAccessKey:@"AKIAJUXN42YLFXA235ZQ"];
    
    NSDate * date = [NSDate date];
    
    double timestamp = [date timeIntervalSince1970];
    
    NSString * fileKey = [@"images/" stringByAppendingFormat:@"%@-%.0f-%@.jpg", 
                          type,
                          timestamp, 
                          [FJPhudgeServerInterface genRandStringLength:8]];
    
    NSData * imageData = UIImageJPEGRepresentation(image, 0.8);
    ASIS3ObjectRequest *request = 
    [ASIS3ObjectRequest PUTRequestForData:imageData
                               withBucket:@"urandium" 
                                      key:fileKey];
    
    [request setAccessPolicy:ASIS3AccessPolicyPublicRead];
    
    [request setCompletionBlock:^{
        NSString * path = [SERVER_URL stringByAppendingString:@"/photo"];
        
        
        NSURL * url = [NSURL URLWithString:path];
        ASIFormDataRequest * request = [[ASIFormDataRequest alloc] initWithURL:url];
        
        [request setPostValue:fileKey forKey:@"s3path"];
        
        if (location) {
            NSString * latLng = [NSString stringWithFormat:@"%f,%f", 
                                 location.coordinate.latitude,
                                 location.coordinate.longitude];
            
            [request setPostValue:latLng forKey:@"latLng"];
        }
        
        [request setPostValue:type forKey:@"type"];
        
        [request setCompletionBlock:^{
            NSLog(@"photo submitted successfully");
            [request release];
        }];
        
        [request setFailedBlock:^{
            NSLog(@"post photo failed");
            [request release];
        }];
        
        [request startAsynchronous];

    }];
    
    [request setFailedBlock:^{
        NSLog(@"could not upload image to S3");
    }];
    [request startAsynchronous];
    
    }

@end
