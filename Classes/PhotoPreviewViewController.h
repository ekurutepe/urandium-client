//
//  PhotoPreviewViewController.h
//  Phudge
//
//  Created by Matteo Caldari on 26/02/2012.
//  Copyright (c) 2012 Matteo Caldari. All rights reserved.
//



@interface PhotoPreviewViewController : UIViewController {
	
	UIImage *_image;
	
	UIImageView *_imageView;
}

@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;


- (id)initWithImage:(UIImage *)image;

@end
