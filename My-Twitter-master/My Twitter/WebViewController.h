//
//  WebViewController.h
//  TwitterClient01
//
//  Created by 穂苅智哉 on 5/29/15.
//  Copyright (c) 2015 Tomoya Hokari. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, strong) NSURL *openURL;

@end