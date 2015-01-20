//
//  AcceptedOfferViewController.m
//  Courtem
//
//  Created by Eliezer de Armas on 30/03/14.
//  Copyright (c) 2014 MVD Forge. All rights reserved.
//

#import "AcceptedOfferViewController.h"
#import "AcceptedOfferCell.h"
#import "DateViewController.h"
#import "CoreDataHelper.h"
#import "User.h"
#import "NSManagedObjectContext+ManagedObjectContextAddition.h"
#import "MyProfileViewController.h"
#import "ChatViewController.h"
#import "CancelDateAlertWindow.h"
#import "LoadingView.h"
#import "NoDataCell.h"

@interface AcceptedOfferViewController () <UITableViewDataSource, UITableViewDelegate,
AcceptedOfferCellDelegate, OHAttributedLabelDelegate, CancelDateDelegate, AlertWindowDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *offers;

@end

@implementation AcceptedOfferViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTitle:NSLocalizedString(@"t_AcceptedOffers", nil)];
    
    // Observers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(offerNotification)
                                                 name:KeyGetOfferNotification object:nil];
    
    // TableView
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // Nibs
    NSBundle *classBundle = [NSBundle bundleForClass:[AcceptedOfferCell class]];
    UINib *nib = [UINib nibWithNibName:@"AcceptedOfferCell" bundle:classBundle];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"AcceptedOfferCell"];
    
    classBundle = [NSBundle bundleForClass:[NoDataCell class]];
    nib = [UINib nibWithNibName:@"NoDataCell" bundle:classBundle];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"NoDataCell"];
    
    // Get offers
    __weak AcceptedOfferViewController *wself = self;
    [ApiHandler getSentOffers:^(BOOL result)
    {
        if (wself)
        {
            if (result)
            {
                [wself loadOffers];
            }
        }
    }];
    
    [ApiHandler getReceivedOffers:^(BOOL result)
     {
         if (wself)
         {
             if (result)
             {
                 [wself loadOffers];
             }
         }
     }];
    
    // Load
    [self loadOffers];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.offers = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [Flurry logEvent:@"Show Accepted Offer Screen"];
}

- (BOOL)arrayContainsOffers:(NSArray *)temp offer:(Offer *)offer
{
    for (Offer *o in temp)
    {
        if ([o.offerID isEqualToString:offer.offerID])
            return YES;
    }
    
    return NO;
}

- (void)loadOffers
{
    NSMutableArray *offers = [NSMutableArray array];
    
    NSArray *accepted = [CoreDataHelper fetchSentOfferWithStatus:OfferStatusAccepted];
    
    if (accepted)
        [offers addObjectsFromArray:accepted];
    
    NSArray *received = [CoreDataHelper fetchReceivedOfferWithStatus:OfferStatusAccepted];
    
    if (received)
        [offers addObjectsFromArray:received];
    
    self.offers = offers;
    
    NSMutableArray *temp = [NSMutableArray arrayWithCapacity:self.offers.count];
    
    for (Offer *o in self.offers)
    {
        if (o.date && o.date.length && [o.rating intValue] == 0 && ![o.poached boolValue])
            [temp addObject:o];
    }
    
    self.offers = [NSArray arrayWithArray:temp];
    
    if (!self.offers.count)
        self.offers = @[@"You have no Accepted Offers at this time."];
    
    temp = [NSMutableArray array];
    
    for (Offer *o in self.offers)
    {
        if (![self arrayContainsOffers:temp offer:o])
            [temp addObject:o];
    }
    
    self.offers = temp;
    
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

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.offers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"AcceptedOfferCell";
    UITableViewCell *c;
    
    if ([self.offers[indexPath.row] isKindOfClass:[Offer class]])
    {
        AcceptedOfferCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        cell.delegate = self;
        cell.text.delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];
        [cell setOffer:self.offers[indexPath.row]];
        c = cell;
    }
    else
    {
        NoDataCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NoDataCell"];
        cell.backgroundColor = [UIColor clearColor];
        cell.text.text = self.offers[0];
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
    l.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    l.text = NSLocalizedString(@"Your Dates", nil);
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
    
    if ([self.offers[indexPath.row] isKindOfClass:[Offer class]])
    {
        NSString *text = [AcceptedOfferCell acceptedText:self.offers[indexPath.row]];
        height = [AcceptedOfferCell estimateHeight:text] + 100;
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

#pragma mark - Actions

- (void)backAction
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - AcceptedOfferCellDelegate

- (void)acceptedOfferPictureAction:(User *)user
{
    [self showInfo:user];
}

- (void)acceptedOfferCancelDate:(Offer *)offer
{
    [Flurry logEvent:@"Cancel Date Action"];
    
    self.view.userInteractionEnabled = NO;
    
    CGRect r = [[UIScreen mainScreen] bounds];
    
    CancelDateAlertWindow *v = [[[NSBundle mainBundle] loadNibNamed:@"CancelDateAlertWindow"
                                                              owner:self options:nil]
                                objectAtIndex:0];
    v.cancelDateDelegate = self;
    v.delegate = self;
    v.offer = offer;
    v.frame = CGRectMake(0, 20, r.size.width, r.size.height);
    [self.navigationController.view addSubview:v];
    [v show];
}

- (void)acceptedOfferChatAction:(User *)user
{
    [Flurry logEvent:@"Create Chat Action"];
    
    [self loadOffers];
    
    [LoadingView showLoadingView:@"Loading Chat..."
                      parentView:self.navigationController.view backColor:YES];
    
    User *u = [CoreDataHelper currentUser];
    NSDictionary *params = @{@"created": @((long)(NSTimeInterval)[[NSDate date] timeIntervalSince1970]), @"participants" : @[u.facebookID, user.facebookID]};
    
    [ApiHandler createChatRoom:params result:^(NSDictionary *json)
     {
         [LoadingView hideLoadingView:self.navigationController.view];
         
         if (json)
         {
             ChatRoom *chatRoom =  [CoreDataHelper fetchFromId:@"ChatRoom" idKeyName:@"chatID" idValue:json[@"id"] context:[NSManagedObjectContext contextForCurrentThread]];
              
             ChatViewController* c = [[ChatViewController alloc]
                                      initWithNibName:@"ChatViewController"
                                      bundle:nil];
             c.chatRoom = chatRoom;
             [self presentViewController:c animated:YES completion:nil];
         }
         else
             showConnectionError();
     }];
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

#pragma mark - AlertWindowDelegate

- (void)hideAlertWindow
{
    self.view.userInteractionEnabled = YES;
}

#pragma mark - CancelDateDelegate

- (void)cancelDateAction:(Offer *)offer
{
    if ([offer.receiverUser.lastOfferID integerValue] == [offer.offerID integerValue])
    {
        [ApiHandler editUser:offer.receiverUser.facebookID params:@{@"lastOfferID" : @"0"}
                      result:nil];
    }
    
    [CoreDataHelper setOfferStatus:offer newStatus:OfferStatusRejected];
    [ApiHandler upOfferStatus:offer.offerID newStatus:OfferStatusRejected
                       result:nil];
    [CoreDataHelper removeOffer:offer];
    [self loadOffers];
}

#pragma mark - Notifications

- (void)offerNotification
{
    //[self loadOffers];
}

@end
