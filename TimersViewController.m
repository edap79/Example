//
//  TimersViewController.m
//  Courtem
//
//  Created by Eliezer de Armas on 30/03/14.
//  Copyright (c) 2014 MVD Forge. All rights reserved.
//

#import "TimersViewController.h"
#import "TimersCell.h"
#import "TimerAlertWindow.h"
#import "ApiHandler.h"
#import "Util.h"
#import "CoreDataHelper.h"
#import "Offer.h"
#import "Timer.h"
#import "NoDataCell.h"
#import "NSManagedObjectContext+ManagedObjectContextAddition.h"
#import "MyProfileViewController.h"
#import "User.h"

@interface TimersViewController () <UITableViewDataSource, UITableViewDelegate, OHAttributedLabelDelegate, TimersCellDelegate, AlertWindowDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *timers;

@end

@implementation TimersViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTitle:NSLocalizedString(@"t_Timers", nil)];
    
    // TableView
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // Nibs
    NSBundle *classBundle = [NSBundle bundleForClass:[TimersCell class]];
    UINib *nib = [UINib nibWithNibName:@"TimersCell" bundle:classBundle];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"TimersCell"];
    
    classBundle = [NSBundle bundleForClass:[NoDataCell class]];
    nib = [UINib nibWithNibName:@"NoDataCell" bundle:classBundle];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"NoDataCell"];
    
    // Load Timers
    [self loadTimers];
    
    // Get timers
    [self updateTimers];
}

- (void)dealloc
{
    self.timers = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [Flurry logEvent:@"Show Timers Screen"];
}

- (void)loadTimers
{
    self.timers = [CoreDataHelper fetchAllTimers];
    
    if (!self.timers.count)
        self.timers = @[@"You have no Timers at this time."];
    
    [self.tableView reloadData];
}

- (void)updateTimers
{
    __weak TimersViewController *wself = self;
    
    [ApiHandler getTimers:^(BOOL result)
     {
         if (wself)
         {
             if (result)
             {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [wself loadTimers];
                 });
             }
         }
     }];
}

- (void)showInfo:(User *)user
{
    MyProfileViewController* vc = [[MyProfileViewController alloc]
                                   initWithNibName:@"MyProfileViewController" bundle:nil];
    vc.user = user;
    vc.isOtherProfile = YES;
    vc.fromDates = YES;
    vc.textTitle = NSLocalizedString(@"t_Profile", nil);
    
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.timers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"TimersCell";
    UITableViewCell *c;
    
    if ([self.timers[indexPath.row] isKindOfClass:[Timer class]])
    {
        TimersCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        cell.delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];
        cell.text.delegate = self;
        [cell update:self.timers[indexPath.row]];
        c = cell;
    }
    else
    {
        NoDataCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NoDataCell"];
        cell.backgroundColor = [UIColor clearColor];
        cell.text.text = self.timers[0];
        c = cell;
    }
    
    return c;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 34)];
    v.backgroundColor = RGBCOLOR(122, 211, 208);
    
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(14, 0, 310, 34)];
    l.textColor = [UIColor whiteColor];
    l.backgroundColor = [UIColor clearColor];
    l.font = [UIFont fontWithName:@"HelveticaNeue" size:17];
    l.text = NSLocalizedString(@"header_0_timers", nil);
    [v addSubview:l];
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 33, 320, .3)];
    line.backgroundColor = RGBCOLOR(105, 105, 105);
    [v addSubview:line];
    
    return v;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 34)];
    v.backgroundColor = RGBCOLOR(122, 211, 208);
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [backButton addTarget:self action:@selector(backAction)
         forControlEvents:UIControlEventTouchUpInside];
    [backButton setFrame:CGRectMake(0, 0, 180, 44)];
    [backButton setTitle:@"Back" forState:UIControlStateNormal];
    [backButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:16]];
    [backButton setImage:[UIImage imageNamed:@"btn_back.png"] forState:UIControlStateNormal];
    [backButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -18, 0, 0)];
    [backButton setImageEdgeInsets:UIEdgeInsetsMake(0, -5, 0, 0)];
    [v addSubview:backButton];
    
    return v;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height;
    
    if ([self.timers[indexPath.row] isKindOfClass:[Timer class]])
    {
        NSString *text = [TimersCell timerText:self.timers[indexPath.row]];
        height = [TimersCell estimateHeight:text] + 76;
    }
    else
        height = 50;
    
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 34;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 64;
}

#pragma mark - OHAttributedLabelDelegate

- (BOOL)attributedLabel:(OHAttributedLabel *)attributedLabel
       shouldFollowLink:(NSTextCheckingResult *)linkInfo
{
    NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
    User *user = [CoreDataHelper fetchFromId:@"User" idKeyName:@"facebookID"
                                     idValue:linkInfo.URL.absoluteString
                                     context:context];
    [self showInfo:user];
    
    return NO;
}

#pragma mark - Actions

- (void)backAction
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - TimersCellDelegate

- (void)endTimer:(Timer *)timer
{
    [Flurry logEvent:@"End Timer Action"];
    
    __weak TimersViewController *wself = self;
    [ApiHandler sendTimer:timer.offer.offerID timer:-1 result:^(BOOL result)
    {
        if (result && wself)
           [wself loadTimers];
    }];
    
    [CoreDataHelper removeTimer:timer];
    [self loadTimers];
}

- (void)timerUserAction:(User *)user
{
    [self showInfo:user];
}

#pragma mark - AlertWindowDelegate

- (void)hideAlertWindow
{
    self.view.userInteractionEnabled = YES;
}

@end
