//
//  TimeLineTableViewController.m
//  TwitterClient01
//
//  Created by 穂苅智哉 on 5/29/15.
//  Copyright (c) 2015 Tomoya Hokari. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import "TimeLineCell.h"
#import "DetailViewController.h"

#import "SharedDataManager.h"

@interface TimeLineTableViewController : UITableViewController

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *text;

@end