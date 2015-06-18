///
//  TimeLineCell.m
//  TwitterClient01
//
//  Created by 穂苅智哉 on 5/29/15.
//  Copyright (c) 2015 Tomoya Hokari. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SharedDataManager.h"

@interface TimeLineCell : UITableViewCell

@property UILabel *tweetTextLabel;
@property UILabel *nameLabel;
@property UILabel *jnameLabel;
@property UILabel *timeLabel;
@property UIImageView *profileImageView;
@property UIImage *image;
@property (nonatomic) CGFloat tweetTextLabelHeight;

@end