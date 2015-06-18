//
//  TimeLineTableViewController.m
//  TwitterClient01
//
//  Created by 穂苅智哉 on 5/29/15.
//  Copyright (c) 2015 Tomoya Hokari. All rights reserved.
//

#import "TimeLineTableViewController.h"


@interface TimeLineTableViewController ()

@property (nonatomic) dispatch_queue_t mainQueue;
@property (nonatomic) dispatch_queue_t imageQueue;
@property (nonatomic, copy) NSString *httpErrorMessage;
@property (nonatomic, copy) NSArray *timeLineData;
//@property (nonatomic, copy) NSString *screen_name;

@end

@implementation TimeLineTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.mainQueue = dispatch_get_main_queue();
    self.imageQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    // iOS6以降のセル再利用のパターン
    [self.tableView registerClass:[TimeLineCell class] forCellReuseIdentifier:@"TimeLineCell"];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    // tableViewの中身が空の場合でも UIRefreshControl を使えるようにする
    self.tableView.alwaysBounceVertical = YES;
    [refreshControl addTarget:self
                       action:@selector(refreshAction:)
             forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    [self getRequest];
}

- (void)getRequest
{
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccount *account = [accountStore accountWithIdentifier:self.identifier];
    
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com"
                  @"/1.1/statuses/home_timeline.json"];
    NSDictionary *params = @{@"count" : @"100",
                             @"trim_user" : @"0",
                             @"include_entities" : @"0"};
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
            if (self.refreshControl.refreshing) {
                [self.refreshControl endRefreshing]; // refreshActionの終了処理をこちらに移動
            }
        });
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshAction:(id)sender
{
    // 更新開始　インジケータON
    [self.refreshControl beginRefreshing];
    
    // 更新処理
    [self getRequest];
    
    // 更新終了　インジケータOFF
    // 通常以下の処理はこのメソッド内で良いが、今回の更新処理は非同期なので
    // dispatch_async()のメインキュー処理ブロック内に記述する必要がある。
    // [self.refreshControl endRefreshing];
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
                                                         forIndexPath:indexPath];
    
    // Configure the cell...
    
    //並列処理のために場合分けする。
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

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
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