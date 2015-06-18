//
//  UserViewController.h
//  TwitterClient01
//
//  Created by 穂苅智哉 on 6/6/15.
//  Copyright (c) 2015 Tomoya Hokari. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>

@interface UserViewController : UIViewController

@property (nonatomic, copy) NSString *screen_name;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *jname;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *idStr;

@end
