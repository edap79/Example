//
//  PoachedViewController.m
//  Courtem
//
//  Created by Eliezer de Armas on 28/03/14.
//  Copyright (c) 2014 MVD Forge. All rights reserved.
//

#import "PoachedViewController.h"
#import "PoachedCell.h"
#import "OHAttributedLabel.h"
#import "NoDataCell.h"
#import "RatingAlertWindow.h"
#import "YourOfferAlertWindow.h"
#import "MyProfileViewController.h"
#import "DateViewController.h"
#import "TimerAlertWindow.h"
#import "CoreDataHelper.h"
#import "User.h"
#import "Offer.h"
#import "NSManagedObjectContext+ManagedObjectContextAddition.h"
#import "BloqUserAlertWindow.h"
#import "WingmanAlertWindow.h"
#import "Util.h"
#import "CalendarHandler.h"
#import "DeckViewController.h"

@interface PoachedViewController () <UITableViewDataSource, UITableViewDelegate, OHAttributedLabelDelegate, PoachedCellDelegate, AlertWindowDelegate,
YourOfferDelegate, TimerAlertDelegate, BloqUserDelegate, WingmanDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *receivedOffers;
@property (strong, nonatomic) NSArray *poachedOffers;
@property (strong, nonatomic) NSArray *upOffers;

@end

@implementation PoachedViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(offerNotification)
                                                 name:KeyGetOfferNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(upOfferNotification)
                                                 name:KeyUpOfferNotification object:nil];
    
    [self setTitle:NSLocalizedString(@"t_Dates", nil)];
    
    // TableView
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self backButton];
    
    // Nibs
    NSBundle *classBundle = [NSBundle bundleForClass:[PoachedCell class]];
    UINib *nib = [UINib nibWithNibName:@"PoachedCell" bundle:classBundle];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"PoachedCell"];
    
    classBundle = [NSBundle bundleForClass:[NoDataCell class]];
    nib = [UINib nibWithNibName:@"NoDataCell" bundle:classBundle];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"NoDataCell"];
    
    // Load offers
    [self loadOffers];
    
    // Get offers
    [self getReceivedOffers];
    [self getPoachedOffers];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.receivedOffers = nil;
    self.poachedOffers = nil;
    self.upOffers = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [Flurry logEvent:@"Show Dates Screen"];
}

- (void)loadOffers
{
    [self loadReceivedOffers];
    [self loadPoachedOffers];
    [self loadUpOffers];
}

- (void)updateOffers
{
    [self loadOffers];
    [self.tableView reloadData];
}

- (void)showInfo:(User *)user
{
    User *currentUser = [CoreDataHelper currentUser];
    
    MyProfileViewController* vc = [[MyProfileViewController alloc]
                                   initWithNibName:@"MyProfileViewController" bundle:nil];
    vc.user = user;
    vc.isOtherProfile = ![currentUser.facebookID isEqualToString:user.facebookID];
    vc.fromDates = YES;
    vc.textTitle = NSLocalizedString(@"t_Profile", nil);
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showInfoModal:(User *)user
{
    User *currentUser = [CoreDataHelper currentUser];
    
    MyProfileViewController* vc = [[MyProfileViewController alloc]
                                   initWithNibName:@"MyProfileViewController" bundle:nil];
    vc.user = user;
    vc.isOtherProfile = ![currentUser.facebookID isEqualToString:user.facebookID];
    vc.fromDates = YES;
    vc.textTitle = NSLocalizedString(@"t_Profile", nil);
    vc.isModal = YES;
    
    UINavigationController *n = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:n animated:YES completion:nil];
}

- (void)getReceivedOffers
{
    __weak PoachedViewController *wself = self;
    
    [ApiHandler getReceivedOffers:^(BOOL result)
     {
         if (wself && result)
             [wself loadReceivedOffers];
     }];
}

- (void)loadReceivedOffers
{
    self.receivedOffers = [CoreDataHelper
                           fetchReceivedOfferWithStatus:OfferStatusCreated];
    
    if (!self.receivedOffers.count)
        self.receivedOffers = @[@"You have no Offers at this time."];
    
    [self.tableView reloadData];
}

- (void)getPoachedOffers
{
    __weak PoachedViewController *wself = self;
    
    [ApiHandler getSentOffers:^(BOOL result)
     {
         if (wself && result)
             [wself loadPoachedOffers];
     }];
}

- (void)loadPoachedOffers
{
    self.poachedOffers = [CoreDataHelper fetchPoachedOffer];
    
    if (!self.poachedOffers.count)
        self.poachedOffers = @[@"You have no Poached Offers at this time."];
    
    [self.tableView reloadData];
}

- (void)loadUpOffers
{
    self.upOffers = [CoreDataHelper fetchSentOfferWithStatus:OfferStatusUpYourGame];
    
    if (!self.upOffers.count)
        self.upOffers = @[@"You have no Up Offers at this time."];
    
    [self.tableView reloadData];
}

- (NSArray *)arrayForSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return self.receivedOffers;
            
        case 1:
            return self.upOffers;
            
        case 2:
            return self.poachedOffers;
            
        default:
            break;
    }
    
    return nil;
}

- (void)backButton
{
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 34)];
    v.backgroundColor = RGBCOLOR(122, 211, 208);
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [backButton addTarget:self action:@selector(backAction)
         forControlEvents:UIControlEventTouchUpInside];
    [backButton setFrame:CGRectMake(0, -6, 180, 44)];
    [backButton setTitle:@"Back" forState:UIControlStateNormal];
    [backButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:16]];
    [backButton setImage:[UIImage imageNamed:@"btn_back.png"] forState:UIControlStateNormal];
    [backButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -18, 0, 0)];
    [backButton setImageEdgeInsets:UIEdgeInsetsMake(0, -5, 0, 0)];
    [v addSubview:backButton];
    
    self.tableView.tableFooterView = v;
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self arrayForSection:section].count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *data = [self arrayForSection:indexPath.section];
    UITableViewCell *c;
    
    if ([data[indexPath.row] isKindOfClass:[Offer class]])
    {
        PoachedCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PoachedCell"];
        cell.delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];
        cell.text.delegate = self;
        cell.timeLabel.delegate = self;
        [cell update:data[indexPath.row] type:indexPath.section];
        
        if (indexPath.section == 0 || indexPath.section == 1)
            cell.line.hidden = data.count - 1 == indexPath.row;
        else
            cell.line.hidden = NO;
        
        c = cell;
    }
    else
    {
        NoDataCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NoDataCell"];
        cell.backgroundColor = [UIColor clearColor];
        cell.text.text = data[0];
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
    NSString *str = [NSString stringWithFormat:@"header_%ld_poached", (long)section];
    l.text = NSLocalizedString(str, nil);
    [v addSubview:l];
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 33, 320, .3)];
    line.backgroundColor = RGBCOLOR(105, 105, 105);
    [v addSubview:line];
    
    return v;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *data = [self arrayForSection:indexPath.section];
    CGFloat height;
    
    if ([data[indexPath.row] isKindOfClass:[Offer class]])
    {
        Offer *offer = data[indexPath.row];
        NSString *text = [PoachedCell poachedTextOffer:offer
                                                  type:indexPath.section];
        height = [PoachedCell estimateHeight:text] + 90;
        
        text = [PoachedCell poachedTimeLabelText:offer type:indexPath.section];
        CGFloat subTextHeight = [PoachedCell estimateSubTextHeight:text];
        
        height += subTextHeight - 15;
        height += [PoachedCell isWingman:offer] ? 55 : 0;
    }
    else
        height = 50;
    
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 34;
}

#pragma mark - OHAttributedLabelDelegate

- (BOOL)attributedLabel:(OHAttributedLabel *)attributedLabel
       shouldFollowLink:(NSTextCheckingResult *)linkInfo
{
    NSArray *arrayData = [linkInfo.URL.absoluteString componentsSeparatedByString:@":="];
    
    if ([arrayData[0] isEqualToString:@"id"])
    {
        NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
        User *user = [CoreDataHelper fetchFromId:@"User" idKeyName:@"facebookID"
                                         idValue:arrayData[1]
                                         context:context];
        [self showInfo:user];
    }
    
    return NO;
}

#pragma mark - Actions

- (void)backAction
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - PoachedCellDelegate

- (void)approvedAction:(Offer *)offer
{
    [Flurry logEvent:@"Accept Offer Action"];
    
    self.view.userInteractionEnabled = NO;
    
    CGRect r = [[UIScreen mainScreen] bounds];
    
    TimerAlertWindow *v = [[[NSBundle mainBundle] loadNibNamed:@"TimerAlertWindow"
                                                         owner:self options:nil]
                           objectAtIndex:0];
    v.offer = offer;
    v.timerAlertDelegate = self;
    v.delegate = self;
    v.frame = CGRectMake(0, 20, r.size.width, r.size.height);
    [self.navigationController.view addSubview:v];
    [v show];
}

- (void)declineAction:(Offer *)offer
{
    [Flurry logEvent:@"Pass Offer Action"];
    
    [CoreDataHelper setOfferStatus:offer newStatus:OfferStatusRejected];
    [self updateOffers];
    
    __weak PoachedViewController *wself = self;
    [ApiHandler upOfferStatus:offer.offerID newStatus:OfferStatusRejected
                       result:^(BOOL result)
     {
         if (result)
             [CoreDataHelper removeOffer:offer];
         
         if (wself)
             [wself updateOffers];
     }];
}

- (void)upOfferAction:(Offer *)offer
{
    [Flurry logEvent:@"Up Offer Action"];
    
    self.view.userInteractionEnabled = NO;
    
    CGRect r = [[UIScreen mainScreen] bounds];
    
    YourOfferAlertWindow *v = [[[NSBundle mainBundle] loadNibNamed:@"YourOfferAlertWindow"
                                                             owner:self options:nil]
                               objectAtIndex:0];
    v.yourOfferdelegate = self;
    v.delegate = self;
    v.offer = offer;
    v.frame = CGRectMake(0, 20, r.size.width, r.size.height);
    [self.navigationController.view addSubview:v];
    [v show];
}

- (void)userInfoAction:(User *)user
{
    [self showInfo:user];
}

- (void)bloqUserAction:(User *)user
{
    [Flurry logEvent:@"Bloq User Action"];
    
    self.view.userInteractionEnabled = NO;
    
    CGRect r = [[UIScreen mainScreen] bounds];
    
    BloqUserAlertWindow *v = [[[NSBundle mainBundle] loadNibNamed:@"BloqUserAlertWindow"
                                                            owner:self options:nil]
                              objectAtIndex:0];

    v.bloqUserDelegate = self;
    v.delegate = self;
    v.user = user;
    v.frame = CGRectMake(0, 20, r.size.width, r.size.height);
    [self.navigationController.view addSubview:v];
    [v show];
}

- (void)makeNewOfferAction:(Offer *)offer
{
    DateViewController *vc = [[DateViewController alloc]
                              initWithNibName:@"DateViewController" bundle:nil];
    vc.user = offer.receiverUser;
    vc.offer = offer;
    vc.updateOffer = YES;
    
    UINavigationController *n = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:n animated:YES completion:nil];
}

- (void)pictureAction:(User *)user
{
    [self showInfo:user];
}

- (void)removeAction:(Offer *)offer
{
    [Flurry logEvent:@"Remove Offer Action"];
    
    [CoreDataHelper setOfferStatus:offer newStatus:-1];
    [self loadReceivedOffers];
    [self loadPoachedOffers];
    [self loadUpOffers];
    
    __weak PoachedViewController *wself = self;
    [ApiHandler deleteOffer:offer.offerID result:^(BOOL result)
     {
         if (result)
             [CoreDataHelper removeOffer:offer];
         
         if (wself)
         {
             [wself loadReceivedOffers];
             [wself loadPoachedOffers];
             [wself loadUpOffers];
         }
     }];
}

- (void)wingmanAction:(Offer *)offer
{
    [Flurry logEvent:@"Wingman Action"];
    
    self.view.userInteractionEnabled = NO;
    
    CGRect r = [[UIScreen mainScreen] bounds];
    
    WingmanAlertWindow *v = [[[NSBundle mainBundle] loadNibNamed:@"WingmanAlertWindow"
                                                           owner:self options:nil]
                             objectAtIndex:0];
    v.parentController = self;
    v.offer = offer;
    v.delegate = self;
    v.wingmanDelegate = self;
    v.frame = CGRectMake(0, 20, r.size.width, r.size.height);
    [self.navigationController.view addSubview:v];
    [v show];
}

- (void)approvedActionFromWingman:(Offer *)offer
{
    [Flurry logEvent:@"Accept Wingman Action"];
    
    [CoreDataHelper setOfferStatus:offer newStatus:OfferStatusAccepted];
    [self loadReceivedOffers];
    [self loadPoachedOffers];
    [self loadUpOffers];
    
    __weak typeof(self) wself = self;
    [ApiHandler upOfferStatus:offer.offerID newStatus:OfferStatusAccepted
                       result:^(BOOL result)
     {
         if (!result)
         {
             if (wself)
             {
                 [CoreDataHelper setOfferStatus:offer newStatus:OfferStatusUpYourGame];
                 [wself loadReceivedOffers];
                 [wself loadPoachedOffers];
                 [wself loadUpOffers];
             }
         }
     }];
    
    if (self.deckViewController)
        [self.deckViewController openLeftViewAnimated:YES];
}

#pragma mark - AlertWindowDelegate

- (void)hideAlertWindow
{
    self.view.userInteractionEnabled = YES;
}

#pragma mark - Notifications

- (void)offerNotification
{
    //[self updateOffers];
}

- (void)upOfferNotification
{
    [self loadUpOffers];
}

#pragma mark - YourOfferDelegate

- (void)yourOfferUpAction
{
    [self loadReceivedOffers];
}

#pragma mark - TimerAlertDelegate

- (void)timerAlertUserAction:(User *)user
{
    [self showInfoModal:user];
}

- (void)timerAlertSetTimer
{
    if (self.deckViewController)
        [self.deckViewController openLeftViewAnimated:YES];
    
    [self loadOffers];
}

#pragma mark - BloqUserDelegate

- (void)bloqUserAlertAction:(User *)user
{
    [CoreDataHelper setUserBloq:user];
    [self loadReceivedOffers];
}

#pragma mark - WingmanDelegate

- (void)wingmanAddFriend:(id)friendInfo offer:(id)offer
{
    Offer *o = (Offer *)offer;
    [CoreDataHelper upOffer:o upOfferText:o.text];
    [self loadReceivedOffers];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"wingman"] = @{@"facebookID" : friendInfo[@"uid"],
                           @"firstName" : friendInfo[@"first_name"],
                           @"lastName" : friendInfo[@"last_name"]};
    params[@"status"] = @(OfferStatusUpYourGame);
    
    __weak PoachedViewController *wself = self;
    [ApiHandler updateOffer:o.offerID params:params result:^(BOOL result)
     {
         if (!result)
         {
             [CoreDataHelper setOfferStatus:o newStatus:OfferStatusCreated];
             
             if (wself)
                 [wself loadReceivedOffers];
         }
     }];
}

@end
