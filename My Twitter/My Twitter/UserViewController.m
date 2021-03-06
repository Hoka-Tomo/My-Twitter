//
//  UserViewController.m
//  My Twitter
//
//  Created by 穂苅智哉 on 6/21/15.
//  Copyright (c) 2015 Tomoya Hokari. All rights reserved.
//

#import "UserViewController.h"
#import "TimeLineCell.h"

@interface UserViewController () <
UITableViewDataSource,
UITableViewDelegate
>

@property (weak, nonatomic) IBOutlet UITextView *nameView;
@property (weak, nonatomic) IBOutlet UITextView *jnameView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;


@property (nonatomic) dispatch_queue_t mainQueue;
@property (nonatomic) dispatch_queue_t imageQueue;
@property (nonatomic, copy) NSString *httpErrorMessage;
@property (nonatomic, copy) NSArray *timeLineData;

@end

@implementation UserViewController

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
    
    self.navigationItem.title = @"User View";
    self.profileImageView.image = self.image;
    self.jnameView.text = self.jname;
    self.nameView.text = self.name;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.mainQueue = dispatch_get_main_queue();
    self.imageQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    // iOS6以降のセル再利用のパターン
    [self.tableView registerClass:[TimeLineCell class] forCellReuseIdentifier:@"TimeLineCell"];
    
    self.tableView.alwaysBounceVertical = YES;
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    //self.refreshControl = refreshControl;
    
    [self getRequest];
    
    //    UITapGestureRecognizer *singleFingerSingleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleFingerSingleTap:)];
    //    [self.nameView addGestureRecognizer:singleFingerSingleTap];
    //
}


// タイムライン表示
- (void)getRequest
{
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccount *account = [accountStore accountWithIdentifier:self.identifier];
    
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com"
                  @"/1.1/statuses/user_timeline.json"];
    NSDictionary *params = @{@"count" : @"100",
                             @"trim_user" : @"0",
                             @"include_entities" : @"0",
                             @"screen_name" : self.name
                            };
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodGET
                                                      URL:url
                                               parameters:params];
    
    request.account = account;
    
    UIApplication *application = [UIApplication sharedApplication];
    application.networkActivityIndicatorVisible = YES; // インジケータON
    
    [request performRequestWithHandler:^(NSData *responseData,
                                         NSHTTPURLResponse *urlResponse,
                                         NSError *error) { // ここからは別スレッド（キュー）
        if (responseData) {
            self.httpErrorMessage = nil;
            if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 300) {
                NSError *jsonError;
                self.timeLineData =
                [NSJSONSerialization JSONObjectWithData:responseData
                                                options:NSJSONReadingAllowFragments
                                                  error:&jsonError];
                if (self.timeLineData) {
                    NSLog(@"Timeline Response: %@\n", self.timeLineData);
                    dispatch_async(dispatch_get_main_queue(), ^{ // UI処理はメインキューで
                        [self.tableView reloadData]; // テーブルビュー書き換え
                    });
                } else { // JSONシリアライズエラー発生時
                    NSLog(@"JSON Error: %@", [jsonError localizedDescription]);
                }
            } else { // HTTPエラー発生時
                self.httpErrorMessage =
                [NSString stringWithFormat:@"The response status code is %zd",
                 urlResponse.statusCode];
                NSLog(@"HTTP Error: %@", self.httpErrorMessage);
                dispatch_async(dispatch_get_main_queue(), ^{ // UI処理はメインキューで
                    [self.tableView reloadData]; // テーブルビュー書き換え
                });
            }
        } else { // リクエスト送信エラー発生時
            NSLog(@"ERROR: An error occurred while requesting: %@", [error localizedDescription]);
            // リクエスト時の送信エラーメッセージを画面に表示する領域がない。今後の課題。
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            UIApplication *application = [UIApplication sharedApplication];
            application.networkActivityIndicatorVisible = NO; // インジケータOFF
            //            if (self.refreshControl.refreshing) {
            //                [self.refreshControl endRefreshing]; // refreshActionの終了処理をこちらに移動
            
        });
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SharedDataManager *sharedManager = [SharedDataManager sharedManager];
    
    NSString *tweetText = self.timeLineData[indexPath.row][@"text"];
    NSAttributedString *attributedTweetText = [sharedManager attributedText:tweetText];
    CGFloat tweetTextLabelHeight = [sharedManager tweetTextLabelHeight:attributedTweetText];
    CGFloat cellHeight = sharedManager.marginY1 + tweetTextLabelHeight
    + sharedManager.marginY2 + sharedManager.nameLabelY + sharedManager.marginY3;
    return  cellHeight;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (!self.timeLineData) {
        return 1;
    } else {
        return self.timeLineData.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TimeLineCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TimeLineCell"
                                                         forIndexPath:indexPath]; //宣言
    
    // Configure the cell...
    
    if (self.httpErrorMessage) {
        cell.tweetTextLabel.text = self.httpErrorMessage;
        cell.tweetTextLabelHeight = 24;
    } else if (!self.timeLineData) {
        cell.tweetTextLabel.text = @"Loading...";
        cell.tweetTextLabelHeight = 24;
    } else {
        //SharedDataManager *sharedManager = [SharedDataManager sharedManager];
        
        NSString *name = self.timeLineData[indexPath.row][@"user"][@"screen_name"];
        NSString *jname = self.timeLineData[indexPath.row][@"user"][@"name"];
        NSString *time = self.timeLineData[indexPath.row][@"created_at"];
        
        /*  created_atで取得した情報を変換?格納
         NSDateFormatter* inFormat = [[NSDateFormatter alloc] init];
         NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
         [inFormat setLocale:locale];
         [inFormat setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss Z"];
         NSDate *dateline = [inFormat dateFromString:time];
         */
        
        NSString *text = [[self.timeLineData objectAtIndex:indexPath.row]objectForKey:@"text"];
        
        cell.tweetTextLabelHeight = [self labelHeight:text];
        cell.tweetTextLabel.text = text;
        
        //cell.nameLabel.text = self.timeLineData[indexPath.row][@"user"][@"screen_name"]; //userの中のscreen_name
        cell.nameLabel.text = name;
        cell.jnameLabel.text = jname;
        cell.timeLabel.text = time;
        cell.profileImageView.image = [UIImage imageNamed:@"blank.png"];
        //cell.tweetTextLabelHeight = [sharedManager tweetTextLabelHeight:attributedTweetText];
        
        UIApplication *application = [UIApplication sharedApplication];
        application.networkActivityIndicatorVisible = YES;
        
        dispatch_async(self.imageQueue, ^{
            NSString *url;
            NSDictionary *tweetDictionary = self.timeLineData[indexPath.row];
            
            if ([[tweetDictionary allKeys] containsObject:@"retweeted_status"]) {
                // リツイートの場合はretweeted_statusキー項目が存在する
                url = tweetDictionary[@"retweeted_status"][@"user"][@"profile_image_url"];
            } else {
                url = tweetDictionary[@"user"][@"profile_image_url"];
            }
            
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
            dispatch_async(self.mainQueue, ^{
                UIApplication *application = [UIApplication sharedApplication];
                application.networkActivityIndicatorVisible = NO;
                UIImage *image = [[UIImage alloc] initWithData:data];
                cell.profileImageView.image = image;
                [cell setNeedsLayout];
            });
        });
    }
    return cell;
}

-(CGFloat)labelHeight:(NSString *)labelText{
    //ラベルの行間設定
    UILabel *aLabel = [[UILabel alloc] init];
    CGFloat lineHeight = 18.0;
    NSMutableParagraphStyle *paragrahStyle = [[NSMutableParagraphStyle alloc] init];
    paragrahStyle.minimumLineHeight = lineHeight;
    paragrahStyle.maximumLineHeight = lineHeight;
    
    //テキスト属性を付与
    NSString *text = (labelText == nil) ? @"" : labelText;
    UIFont *font = [UIFont fontWithName:@"HiraKakuProN-W3" size:14];
    NSDictionary *attributes = @{NSParagraphStyleAttributeName: paragrahStyle,
                                 NSFontAttributeName: font};
    NSAttributedString *aText = [[NSAttributedString alloc]initWithString:text attributes:attributes];
    aLabel.attributedText = aText;
    
    //ラベルの高さを計算
    CGFloat aHeight = [aLabel.attributedText boundingRectWithSize:CGSizeMake(257, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size.height;
    return aHeight;
}


/*
 #pragma mark - Navigation
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TimeLineCell *cell = (TimeLineCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    DetailViewController *detailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"DetailViewController"];
    detailViewController.name = cell.nameLabel.text;
    detailViewController.jname = cell.jnameLabel.text;
    detailViewController.time = cell.timeLabel.text;
    detailViewController.text = cell.tweetTextLabel.text;
    detailViewController.image = cell.profileImageView.image;
    detailViewController.identifier = self.identifier;
    detailViewController.idStr = self.timeLineData[indexPath.row][@"id_str"];
    
    [self.navigationController pushViewController:detailViewController animated:YES];
}


@end
