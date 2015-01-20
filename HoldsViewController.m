//
//  HoldsViewController.m
//  Courtem
//
//  Created by Eliezer de Armas on 30/03/14.
//  Copyright (c) 2014 MVD Forge. All rights reserved.
//

#import "HoldsViewController.h"
#import "HoldCell.h"
#import "DateViewController.h"
#import "CoreDataHelper.h"
#import "User.h"
#import "NoDataCell.h"

@interface HoldsViewController () <UITableViewDataSource, UITableViewDelegate,
HoldCellDelegate, DateDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *holds;

@end

@implementation HoldsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTitle:NSLocalizedString(@"t_Holds", nil)];
    
    // TableView
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // Nibs
    NSBundle *classBundle = [NSBundle bundleForClass:[HoldCell class]];
    UINib *nib = [UINib nibWithNibName:@"HoldCell" bundle:classBundle];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"HoldCell"];
    
    // Load
    [self loadHolders];
}

- (void)dealloc
{
    self.holds = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [Flurry logEvent:@"Show Holds Screen"];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [ApiHandler updateUsersHold:nil];
}

- (BOOL)containsUserId:(NSArray *)array userId:(NSString *)userId
{
    for (User *u in array)
    {
        if ([u.facebookID isEqualToString:userId])
            return YES;
    }
    
    return NO;
}

- (NSArray *)removeDuplicateUsers:(NSArray *)array
{
    NSMutableArray *mutable = [NSMutableArray array];
    
    for (User *u in array)
    {
        if (![self containsUserId:mutable userId:u.facebookID])
            [mutable addObject:u];
    }
    
    return mutable;
}

- (void)loadHolders
{
    self.holds = [self removeDuplicateUsers:[CoreDataHelper fetchHolders]];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.holds.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"HoldCell";
    
    HoldCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    cell.delegate = self;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    [cell setUser:self.holds[indexPath.row]];
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 34)];
    v.backgroundColor = RGBCOLOR(122, 211, 208);
    
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(14, 0, 310, 34)];
    l.textColor = [UIColor whiteColor];
    l.backgroundColor = [UIColor clearColor];
    l.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    l.text = NSLocalizedString(@"header_0_holds", nil);
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
    return 113;
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

#pragma mark - HoldCellDelegate

- (void)holdCellCourtAction:(User *)user
{
    DateViewController *vc = [[DateViewController alloc]
                              initWithNibName:@"DateViewController" bundle:nil];
    vc.delegate = self;
    vc.fromProfile = YES;
    vc.user = user;
    
    UINavigationController *n = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:n animated:YES completion:nil];
}

- (void)holdCellRemoveAction:(User *)user
{
    [Flurry logEvent:@"Remove Hold Action"];
    
    [CoreDataHelper removeHoldState:user];
    [self loadHolders];
}

#pragma mark - DateDelegate

- (void)dateSubmit:user
{
    [self holdCellRemoveAction:user];
}

@end
