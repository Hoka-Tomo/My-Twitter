//
//  TweetSheetViewController.h
//  My Twitter
//
//  Created by 穂苅智哉 on 6/21/15.
//  Copyright (c) 2015 Tomoya Hokari. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>

@interface TweetSheetViewController : UIViewController <UITextViewDelegate>

@property (nonatomic, copy) NSString *identifier;

@end