//
//  ChatListViewController.m
//  Courtem
//
//  Created by Eliezer de Armas on 03/04/14.
//  Copyright (c) 2014 MVD Forge. All rights reserved.
//

#import "ChatListViewController.h"
#import "ChatListCell.h"
#import "ChatViewController.h"
#import "ApiHandler.h"
#import "CoreDataHelper.h"
#import "User.h"
#import "ConfirmAlertWindow.h"
#import "IIViewDeckController.h"
#import "ChatRoom.h"

@interface ChatListViewController () <UITableViewDataSource, UITableViewDelegate, ConfirmDelegate, AlertWindowDelegate, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *chats;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@end

@implementation ChatListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    [self showBottomView:NO];
    
    // Title
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 215, 44)];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"HelveticaNeue" size:17.0];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.text = NSLocalizedString(@"t_AllTheCouples", nil);
    self.navigationItem.titleView = label;
    
    // SearchBar
    self.searchBar.delegate = self;
    
    // TableView
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    // Nibs
    NSBundle *classBundle = [NSBundle bundleForClass:[ChatListCell class]];
    UINib *nib = [UINib nibWithNibName:@"ChatListCell" bundle:classBundle];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"ChatListCell"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([User isLogin])
    {
        // Get chats
        [self fetchChats];
        [self getChats];
    }
    
    [Flurry logEvent:@"Show Chat List Screen"];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.view endEditing:YES];
    [super viewDidDisappear:animated];
}

- (void)getChats
{
    // Get chats
    [ApiHandler getChats:^(BOOL result)
     {
         [self fetchChats];
     }];
}

- (void)fetchChats
{
    self.chats = [CoreDataHelper fetchAllChats];
    
    if (self.searchBar.text.length)
    {
        NSMutableArray *temp = [NSMutableArray arrayWithCapacity:self.chats.count];
        
        for (ChatRoom *chat in self.chats)
        {
            NSString *user = [chat getOtherUser].fullName;
            NSRange nameRange = [user rangeOfString:self.searchBar.text options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)];
            
            if (nameRange.location != NSNotFound)
                [temp addObject:chat];
        }
        
        self.chats = temp;
    }
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.chats.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"ChatListCell";
    
    ChatListCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    [cell update:self.chats[indexPath.row]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [Flurry logEvent:@"Select Chat Action"];
    
    ChatViewController* vc = [[ChatViewController alloc]
                              initWithNibName:@"ChatViewController"
                              bundle:nil];
    vc.chatRoom = self.chats[indexPath.row];
    
    [self presentViewController:vc animated:YES completion:nil];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        self.view.userInteractionEnabled = NO;
        
        CGRect r = [[UIScreen mainScreen] bounds];
        
        ConfirmAlertWindow *v = [[[NSBundle mainBundle] loadNibNamed:@"ConfirmAlertWindow"
                                                               owner:self options:nil]
                                 objectAtIndex:0];
        v.confirmDelegate = self;
        v.delegate = self;
        v.data = @(indexPath.row);
        v.text = @"Are you sure you want to delete this chat? This can’t be undone.";
        v.frame = CGRectMake(0, 20, r.size.width, r.size.height);
        [self.deckViewController.view addSubview:v];
        [v show];
    }
}

#pragma mark - ConfirmDelegate

- (void)confirmAction:(BOOL)isYes info:(id)info
{
    if (isYes)
    {
        [Flurry logEvent:@"Delete Chat Action"];
        
        ChatRoom *chatRoom = self.chats[[info integerValue]];
        [CoreDataHelper removeChat:chatRoom removed:YES];
        [self fetchChats];
        
        [ApiHandler editChat:[chatRoom.chatID stringValue]
                      params:@{@"removed" : @(YES)}
                      result:^(BOOL result)
         {
             if (!result)
             {
                 [CoreDataHelper removeChat:chatRoom removed:YES];
                 [self fetchChats];
             }
         }];
    }
}

#pragma mark - AlertWindowDelegate

- (void)hideAlertWindow
{
    self.view.userInteractionEnabled = YES;
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    self.searchBar.text = @"";
    [self.view endEditing:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchBar.text = @"";
    [self.view endEditing:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self fetchChats];
}

@end
