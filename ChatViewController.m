//
//  ChatViewController.m
//  Courtem
//
//  Created by Eliezer de Armas on 30/03/14.
//  Copyright (c) 2014 MVD Forge. All rights reserved.
//

#import "ChatViewController.h"
#import "ChatCell.h"
#import "ChatRedCell.h"
#import "MyProfileViewController.h"
#import "User.h"
#import "CustomImageView.h"
#import "CoreDataHelper.h"
#import "Util.h"
#import "ChatRoom.h"
#import "Message.h"
#import "NSManagedObjectContext+ManagedObjectContextAddition.h"
#import "TPKeyboardAvoidingScrollView.h"

@interface ChatViewController () <UITableViewDataSource, UITableViewDelegate,
UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *topBarview;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;
@property (weak, nonatomic) IBOutlet UIView *contentViewTitle;
@property (weak, nonatomic) IBOutlet CustomImageView *titleImage;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *writeContentView;
@property (weak, nonatomic) IBOutlet CustomImageView *pictureImageView;
@property (weak, nonatomic) IBOutlet UIView *contentTextField;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (strong, nonatomic) NSArray *messages;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;
@property (strong, nonatomic) User *otherUser;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (assign, nonatomic) CGFloat lastTextViewHeight;
@property (weak, nonatomic) IBOutlet TPKeyboardAvoidingScrollView *keyboardScroll;

@end

@implementation ChatViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = YES;
    self.view.backgroundColor = [UIColor blackColor];
    
    // Notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateChat)
                                                 name:KeyUpdateChatNotification
                                               object:nil];
    
    // Nibs
    NSBundle *classBundle = [NSBundle bundleForClass:[ChatCell class]];
    UINib *nib = [UINib nibWithNibName:@"ChatCell" bundle:classBundle];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"ChatCell"];
    
    classBundle = [NSBundle bundleForClass:[ChatRedCell class]];
    nib = [UINib nibWithNibName:@"ChatRedCell" bundle:classBundle];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"ChatRedCell"];
    
    // TopBar
    self.topBarview.backgroundColor = RGBCOLOR(122, 211, 208);
    
    // Back button
    self.backButton.backgroundColor = [UIColor clearColor];
    [self.backButton setTitle:@"Close" forState:UIControlStateNormal];
    [self.backButton setImageEdgeInsets:UIEdgeInsetsMake(0, -28, 0, 0)];
    [self.backButton addTarget:self action:@selector(backAction)
              forControlEvents:UIControlEventTouchUpInside];
    
    // Info button
    self.infoButton.backgroundColor = [UIColor clearColor];
    [self.infoButton setTitle:@"" forState:UIControlStateNormal];
    [self.infoButton setImage:[UIImage imageNamed:@"btn_info_white.png"]
                     forState:UIControlStateNormal];
    [self.infoButton addTarget:self action:@selector(infoAction)
              forControlEvents:UIControlEventTouchUpInside];
    
    // Picture
    [self.pictureImageView showIndicator:NO];
    self.pictureImageView.clipsToBounds = YES;
    self.pictureImageView.layer.cornerRadius = self.pictureImageView.frame.size.width / 2;
    
    // Title image
    self.titleImage.clipsToBounds = YES;
    self.titleImage.layer.cornerRadius = self.titleImage.frame.size.width / 2;
    [self.titleImage showIndicator:NO];
    
    // Title
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:17];
    self.titleLabel.text = @"Laura";
    
    // TableView
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // Gesture
    self.tapGesture = [[UITapGestureRecognizer alloc]
                       initWithTarget:self action:@selector(tapGestureAction)];
    self.tapGesture.enabled = NO;
    [self.tableView addGestureRecognizer:self.tapGesture];
    
    // Content TextField
    self.contentTextField.layer.cornerRadius = 5;
    
    // TextField
    NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"Message" attributes:@{ NSForegroundColorAttributeName : RGBCOLOR(51, 51, 51)}];
    self.textField.attributedPlaceholder = str;
    self.textField.userInteractionEnabled = NO;
    
    // TextView
    self.textView.delegate = self;
    
    // Send button
    self.sendButton.alpha = 0;
    
    // Load info
    [self loadInfo];
}

- (void)dealloc
{
    [self.tableView removeGestureRecognizer:self.tapGesture];
    self.tapGesture = nil;
    self.chatRoom = nil;
    self.otherUser = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [Flurry logEvent:@"Show Chat Screen"];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self.titleLabel sizeToFit];
    self.titleLabel.frame = CGRectSetHeight(self.titleLabel.frame, 44);
    
    self.contentViewTitle.frame =
    CGRectSetWidth(self.contentViewTitle.frame,
                   CGRectGetWidth(self.titleImage.frame) +
                   CGRectGetWidth(self.titleLabel.frame) + 7);
    self.contentViewTitle.center = CGPointMake(160, 22);
    self.lastTextViewHeight = self.textView.contentSize.height;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (NSInteger)estimateHeight:(NSInteger)row
{
    if ([self.messages[row] isKindOfClass:[Message class]])
    {
        return sizeOfLabelWithText(((Message *)self.messages[row]).text,
                                   [UIFont fontWithName:@"HelveticaNeue" size:12],
                                   CGSizeMake(188, 0), 0).height;
    }
    
    return sizeOfLabelWithText(self.messages[row],
                               [UIFont fontWithName:@"HelveticaNeue" size:12],
                               CGSizeMake(188, 0), 0).height;
}

- (void)loadInfo
{
    User *user = [CoreDataHelper currentUser];
    self.otherUser = [self.chatRoom getOtherUser];
    
    [self.titleImage loadImageWithURL:[self.otherUser firstUrl]];
    self.titleLabel.text = self.otherUser.firstName;
    [self.pictureImageView loadImageWithURL:[user firstUrl]];
    
    self.messages = [self.chatRoom getMessages:YES];
    NSDate *lastMessageDate;
    
    if (self.messages.count)
    {
        CGFloat interval = [((Message *)self.messages[0]).created doubleValue];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        NSString *s = [formatter stringFromDate:
                       [NSDate dateWithTimeIntervalSince1970:interval]];
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        lastMessageDate = [formatter dateFromString:s];
    }
    else
        lastMessageDate = [NSDate date];
    
    NSArray *array = [Util lastChatDateString:lastMessageDate];
    self.timeLabel.text = [NSString stringWithFormat:@"%@ %@", array[0], array[1]];
    self.timeLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12];
    
    NSMutableAttributedString *attrStr = [self.timeLabel.attributedText mutableCopy];
    [attrStr addAttribute:NSFontAttributeName
                    value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:12]
                    range:[self.timeLabel.text rangeOfString:array[0]]];
    self.timeLabel.attributedText = attrStr;
    
    [self.tableView reloadData];
}

- (void)showInfo
{
    MyProfileViewController *vc = [[MyProfileViewController alloc]
                                   initWithNibName:@"MyProfileViewController" bundle:nil];
    vc.isOtherProfile = YES;
    vc.user = self.otherUser;
    vc.withCourt = NO;
    vc.isModal = YES;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)sendText:(NSString *)text
{
    NSDictionary *params = @{/*@"created" : @([Util newMessageTimestamp]),*/
                             @"chat_room" : self.chatRoom.chatID,
                             @"sender" : [CoreDataHelper currentUser].facebookID,
                             @"text" : text};
    
    NSMutableArray *temp = [NSMutableArray arrayWithArray:self.messages];
    [temp addObject:text];
    self.messages = temp;
    [self reloadAndScroll];
    
    self.sendButton.enabled = NO;
    self.textView.text = @"";
    [self updateTextWhileWrite:33];
    
    __weak ChatViewController *wself = self;
    [ApiHandler sendNewChatMessage:params result:^(BOOL result)
     {
         if (result && wself)
         {
             [wself loadInfo];
             [self reloadAndScroll];
         }
         else
             showConnectionError();
     }];
}

- (void)reloadAndScroll
{
    [self.tableView reloadData];
    self.tableView.contentSize = CGSizeMake(self.tableView.contentSize.width,
                                            self.tableView.contentSize.height + 40);
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 320,
                                                   self.tableView.contentSize.height + 40)
                               animated:YES];
    [self.tableView reloadData];
}

- (void)updateTextWhileWrite:(CGFloat)newHeight
{
    newHeight = MIN(newHeight, 117);
    
    if (newHeight != self.lastTextViewHeight)
    {
        CGFloat increment = newHeight * 1.3;
        CGFloat diff = CGRectGetHeight(self.writeContentView.frame) - increment;
        
        self.writeContentView.frame = CGRectSetHeight(self.writeContentView.frame,
                                                      increment);
        self.writeContentView.frame =
        CGRectSetY(self.writeContentView.frame,
                   CGRectGetMinY(self.writeContentView.frame) + diff);
        self.lastTextViewHeight = newHeight;
    }
}

#pragma mark - KeyBoard

- (void)keyboardWillShow
{
    [super keyboardWillShow];
    
    self.tapGesture.enabled = YES;
    self.sendButton.enabled = NO;
    
    [UIView animateWithDuration:.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:
     ^{
         self.contentTextField.frame = CGRectSetWidth(self.contentTextField.frame, 215);
         self.sendButton.alpha = 1;
     }
                     completion:nil];
}

- (void)keyboardWasShown
{
    [super keyboardWasShown];
    
    [UIView animateWithDuration:.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:
     ^{
         self.tableView.frame = CGRectMake(CGRectGetMinX(self.tableView.frame),
                                           CGRectGetMinY(self.tableView.frame) + 216,
                                           CGRectGetWidth(self.tableView.frame),
                                           CGRectGetHeight(self.tableView.frame) - 216);
     }
                     completion:nil];
    
    [self reloadAndScroll];
}

- (void)keyboardWillHide
{
    [super keyboardWillHide];
    
    self.tapGesture.enabled = NO;
    self.textField.text = @"";
    
    self.tableView.frame = CGRectMake(CGRectGetMinX(self.tableView.frame),
                                      CGRectGetMinY(self.tableView.frame) - 216,
                                      CGRectGetWidth(self.tableView.frame),
                                      CGRectGetHeight(self.tableView.frame) + 216);
    
    [UIView animateWithDuration:.1
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:
     ^{
         self.contentTextField.frame = CGRectSetWidth(self.contentTextField.frame, 264);
         self.sendButton.alpha = 0;
     }
                     completion:nil];
    
    [self reloadAndScroll];
}

#pragma mark - Actions

- (void)backAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)infoAction
{
    [self showInfo];
}

- (void)tapGestureAction
{
    self.textView.text = @"";
    [self.view endEditing:YES];
}

- (IBAction)textFieldEditingChanged:(id)sender
{
}

- (IBAction)sendChat:(id)sender
{
    [Flurry logEvent:@"Send New Chat Action"];
    
    [self sendText:self.textView.text];
    [self.textView resignFirstResponder];
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if ([self.messages[indexPath.row] isKindOfClass:[Message class]])
    {
        Message *m = (Message *)self.messages[indexPath.row];
        BOOL isOther = [m.sender.facebookID isEqualToString:self.otherUser.facebookID];
        NSString *identifier = isOther ? @"ChatCell" : @"ChatRedCell";
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];
        
        if (isOther)
            [((ChatCell *)cell) update:m.text user:m.sender];
        else
            [((ChatRedCell *)cell) update:m.text];
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"ChatRedCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];
        [((ChatRedCell *)cell) update:self.messages[indexPath.row]];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self estimateHeight:indexPath.row] + 23;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row % 2 == 0 && indexPath.row < 3)
        [self showInfo];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.textField.hidden = YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    self.textField.hidden = NO;
}

- (void)textViewDidChange:(UITextView *)textView
{
    self.sendButton.enabled = self.textView.text.length > 0;
    CGFloat newHeight = textView.contentSize.height;
    [self updateTextWhileWrite:newHeight];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"])
    {
        [self sendText:self.textView.text];
        [textView resignFirstResponder];
       
        return NO;
    }
    
    return YES;
}

#pragma mark - Notification

- (void)updateChat
{
    [self loadInfo];
    [self reloadAndScroll];
}

@end
