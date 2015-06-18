//
//  DetailViewController.m
//  TwitterClient01
//
//  Created by 穂苅智哉 on 5/29/15.
//  Copyright (c) 2015 Tomoya Hokari. All rights reserved.
//

#import "DetailViewController.h"
#import "UserViewController.h"

@interface DetailViewController ()
@property (weak, nonatomic) IBOutlet UITextView *nameView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (nonatomic, copy) NSString *httpErrorMessage;

@end

@implementation DetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"Detail View";
    self.profileImageView.image = self.image;
    self.nameView.text = self.name;
    self.nameView.text = self.jname;
    
    // ラベル(nameView)にタップするとアクションを起こせる機能をつけた。
    UITapGestureRecognizer *singleFingerSingleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleFingerSingleTap:)];
    [self.nameView addGestureRecognizer:singleFingerSingleTap];
    
}

- (void)handleSingleFingerSingleTap:(UITapGestureRecognizer *)recognizer //外で実行
{
        UserViewController *userViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UserViewController"];
        userViewController.name = self.name;
        userViewController.text = self.jname;
        userViewController.text = self.text;
        userViewController.image = self.image;
        userViewController.identifier = self.identifier;
        //userViewController.idStr = self.timeLineData[indexPath.row][@"id_str"];
    
        [self.navigationController pushViewController:userViewController animated:YES];
    
    
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

// retweet 機能
- (IBAction)retweetAction:(id)sender {

    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccount *account = [accountStore accountWithIdentifier:self.identifier];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com"
                                       @"/1.1/statuses/retweet/%@.json", self.idStr]];
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodPOST
                                                      URL:url
                                               parameters:nil];
    request.account = account;
    
    UIApplication *application = [UIApplication sharedApplication];
    application.networkActivityIndicatorVisible = YES;
    
    [request performRequestWithHandler:^(NSData *responseData,
                                         NSHTTPURLResponse *urlResponse,
                                         NSError *error) {
        if (responseData) {
            self.httpErrorMessage = nil;
            if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 300) {
                NSDictionary *postResponseData =
                [NSJSONSerialization JSONObjectWithData:responseData
                                                options:NSJSONReadingMutableContainers
                                                  error:NULL];
                NSLog(@"SUCCESS! Created Retweet with ID: %@", postResponseData[@"id_str"]);
            } else { // HTTPエラー発生時
                self.httpErrorMessage =
                [NSString stringWithFormat:@"The response status code is %zd",
                 urlResponse.statusCode];
                NSLog(@"HTTP Error: %@", self.httpErrorMessage);
                // リツイート時のHTTPエラーメッセージを画面に表示する領域がない。今後の課題。
            }
        } else { // リクエスト送信エラー発生時
            NSLog(@"ERROR: An error occurred while posting: %@", [error localizedDescription]);
            // リクエスト時の送信エラーメッセージを画面に表示する領域がない。今後の課題。
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            UIApplication *application = [UIApplication sharedApplication];
            application.networkActivityIndicatorVisible = NO;
        });
    }];
}

// Favorites 機能

- (IBAction)favoriteAction:(id)sender {
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccount *account = [accountStore accountWithIdentifier:self.identifier];

//    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com"
//                                       @"/1.1/favorites/create/%@.json", self.idStr]];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com"
                                       @"/1.1/favorites/create.json"]];
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodPOST
                                                      URL:url
                                               parameters:@{@"id": self.idStr}]; //parameter のここを修正。
    request.account = account;
    
    UIApplication *application = [UIApplication sharedApplication];
    application.networkActivityIndicatorVisible = YES;
    
    [request performRequestWithHandler:^(NSData *responseData,
                                         NSHTTPURLResponse *urlResponse,
                                         NSError *error) {
        if (responseData) {
            self.httpErrorMessage = nil;
            if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 300) {
                NSDictionary *postResponseData =
                [NSJSONSerialization JSONObjectWithData:responseData
                                                options:NSJSONReadingMutableContainers
                                                  error:NULL];
                NSLog(@"SUCCESS! Created Favorites with ID: %@", postResponseData[@"id_str"]);
            } else { // HTTPエラー発生時
                self.httpErrorMessage =
                [NSString stringWithFormat:@"The response status code is %zd",
                 urlResponse.statusCode];
                NSLog(@"HTTP Error: %@", self.httpErrorMessage);
                // リツイート時のHTTPエラーメッセージを画面に表示する領域がない。今後の課題。
            }
        } else { // リクエスト送信エラー発生時
            NSLog(@"ERROR: An error occurred while posting: %@", [error localizedDescription]);
            // リクエスト時の送信エラーメッセージを画面に表示する領域がない。今後の課題。
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            UIApplication *application = [UIApplication sharedApplication];
            application.networkActivityIndicatorVisible = NO;
        });
    }];

}

// Cancel Favorites 機能

- (IBAction)cancelFavoAction:(id)sender {
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccount *account = [accountStore accountWithIdentifier:self.identifier];
    NSString *urlString = [NSString stringWithFormat:@"https://api.twitter.com"
                           @"/1.1/favorites/destroy.json"];
    NSURL *url = [NSURL URLWithString:urlString];
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodPOST
                                                      URL:url
                                               parameters:@{@"id": self.idStr}];
    
    [request setAccount:account];
    
    UIApplication *application = [UIApplication sharedApplication];
    application.networkActivityIndicatorVisible = YES;
    
    [request performRequestWithHandler:^(NSData *responseData,
                                         NSHTTPURLResponse *urlResponse,
                                         NSError *error){
        if(responseData){
            NSInteger statusCode = urlResponse.statusCode;
            if(statusCode >= 200 && statusCode < 300){
                NSDictionary *postResponseData =
                [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:NULL];
                NSLog(@"SUCCESS! Created Favorites with ID: %@", postResponseData[@"id_str"]);
            } else { // HTTPエラー発生時
                self.httpErrorMessage =
                [NSString stringWithFormat:@"The response status code is %zd",
                 urlResponse.statusCode];
                NSLog(@"HTTP Error: %@", self.httpErrorMessage);
                // リツイート時のHTTPエラーメッセージを画面に表示する領域がない。今後の課題。
            }
        } else { // リクエスト送信エラー発生時
            NSLog(@"ERROR: An error occurred while posting: %@", [error localizedDescription]);
            // リクエスト時の送信エラーメッセージを画面に表示する領域がない。今後の課題。
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            UIApplication *application = [UIApplication sharedApplication];
            application.networkActivityIndicatorVisible = NO;
        });
    }];

}

@end