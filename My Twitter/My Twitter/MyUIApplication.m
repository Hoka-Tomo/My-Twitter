//
//  MyUIApplication.m
//  My Twitter
//
//  Created by 穂苅智哉 on 6/21/15.
//  Copyright (c) 2015 Tomoya Hokari. All rights reserved.
//

#import "MyUIApplication.h"

@implementation MyUIApplication

- (BOOL)openURL:(NSURL *)url // UIApplicationのopenURLを上書き
{
    if (!url) {
        return NO;
    }
    
    self.myOpenURL = url;
    AppDelegate *appDelegate = (AppDelegate *)[self delegate];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                         bundle:[NSBundle mainBundle]];
    WebViewController *webViewController = [storyboard instantiateViewControllerWithIdentifier:@"WebViewController"];
    webViewController.openURL = self.myOpenURL;
    webViewController.title = @"Web View";
    [appDelegate.navigationController pushViewController:webViewController animated:YES];
    self.myOpenURL = nil;
    return YES;
}

@end