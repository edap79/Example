//
//  DateViewController.m
//  Courtem
//
//  Created by Eliezer de Armas on 27/03/14.
//  Copyright (c) 2014 MVD Forge. All rights reserved.
//

#import "DateViewController.h"
#import "ProfileImagesGalleryCell.h"
#import "OHAttributedLabel.h"
#import "PhotoFullView.h"
#import "DateCalendarViewController.h"
#import "CustomImageView.h"
#import "User.h"
#import "Location.h"
#import "Offer.h"
#import "CoreDataHelper.h"
#import "Util.h"
#import "MyProfileViewController.h"
#import "ProfilePictureUrl.h"
#import "NSManagedObjectContext+ManagedObjectContextAddition.h"

@interface DateViewController () <OHAttributedLabelDelegate, PhotoFullDelegate,
DateCalendarDelegate>

@property (weak, nonatomic) IBOutlet UIView *contentViewPhoto;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIView *contentViewText2;
@property (weak, nonatomic) IBOutlet OHAttributedLabel *text2Label;
@property (weak, nonatomic) IBOutlet UIView *contentViewText3;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (weak, nonatomic) IBOutlet UIView *starContentView;
@property (weak, nonatomic) IBOutlet UILabel *acceptedLabel;
@property (weak, nonatomic) IBOutlet UILabel *notYetRatedLabel;
@property (weak, nonatomic) IBOutlet UIView *timerContentView;
@property (weak, nonatomic) IBOutlet UIView *acceptedContentView;
@property (weak, nonatomic) IBOutlet UIView *submitContentView;
@property (weak, nonatomic) IBOutlet UILabel *offertHeaderLabel;
@property (strong, nonatomic) NSArray *arrayPhotos;

@end

@implementation DateViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTitle:NSLocalizedString(@"t_Date", nil)];
    
    // Back
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [backButton setTitle:@"Cancel" forState:UIControlStateNormal];
    backButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:17];
    backButton.frame = CGRectMake(0, 0, 60, 44);
    backButton.backgroundColor = [UIColor clearColor];
    [backButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [backButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -15, 0, 0)];
    
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.navigationItem.leftBarButtonItem = backButtonItem;
    
    [self.pageControl setCurrentPage:0];
    
    // Notifications
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(textViewChange)
                   name:UITextViewTextDidChangeNotification
                 object:self.textView];
    
    // Content photo
    self.contentViewPhoto.clipsToBounds = YES;
    self.contentViewPhoto.layer.cornerRadius = 6;
    
    // Photos
    self.arrayPhotos = [NSArray arrayWithArray:[self.user arrayOfUrls]];
    
    [self.collectionView registerClass:[ProfileImagesGalleryCell class] forCellWithReuseIdentifier:@"ProfileImagesGalleryCellId"];
    self.collectionView.backgroundColor = RGBCOLOR(242, 242, 242);
    
    // Name
    self.nameLabel.text = [NSString stringWithFormat:@"%@, %ld", self.user.firstName,
                           (long)[self.user.age integerValue]];
    
    // Rating
    [self setRating:[self.user.userRating integerValue]];
    
    // Info label
    self.infoLabel.text = [NSString stringWithFormat:@"%.0f miles away",
                           [self.user distance]];
    
    if ([self.user.lastUpdated intValue] != 0)
    {
        self.infoLabel.text = [NSString stringWithFormat:@"%@ (active %@ ago)",
                               self.infoLabel.text,
                               [Util elapsedTimeStringFromInterval:self.user.lastUpdated]];
    }
    
    // ContentView text2
    self.contentViewText2.clipsToBounds = YES;
    self.contentViewText2.layer.cornerRadius = 6;
    
    // Acepted label
    self.acceptedLabel.text = [NSString stringWithFormat:@"%@ has currently accepted -",
                               self.user.firstName];
    
    // Text2
    self.text2Label.lineBreakMode = NSLineBreakByWordWrapping;
    self.text2Label.delegate = self;
    self.text2Label.underlineLinks = YES;
    self.text2Label.linkColor = RGBCOLOR(144, 134, 83);
    
    // ContentView text3
    self.contentViewText3.clipsToBounds = YES;
    self.contentViewText3.layer.cornerRadius = 6;
    
    // Offer
    if (self.offer && [self.offer.status integerValue] != OfferStatusAccepted
        && !self.updateOffer)
    {
        self.offer = nil;
    }
    
    // Offert header
    self.offertHeaderLabel.text = [self withOtherOffer] ?
    @"Beat the Competition and Make Your Own Offer" : @"Submit Your Date. Court them with Courtem!";
    
    // TextView
    if (self.updateOffer)
        self.textView.text = self.offer.text;
    
    // Submit button
    self.submitButton.layer.cornerRadius = 3;
    
    // Count label
    self.countLabel.text = @"140";
    [self textViewChange];
    
    // Other Offer
    self.timerContentView.hidden = YES;
    self.acceptedContentView.hidden = YES;
    
    if ([self.user.lastOfferID intValue] > 0 && !self.offer)
        [self fetchLastOffer];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.user = nil;
    self.offer = nil;
    self.arrayPhotos = nil;
}

- (void)showPhotoFull:(NSIndexPath *)indexPath
{
    self.view.userInteractionEnabled = NO;
    
    ProfileImagesGalleryCell *cell = (ProfileImagesGalleryCell *)
    [self.collectionView cellForItemAtIndexPath:indexPath];
    
    CGRect imageFrame = cell.imageView.frame;
    imageFrame.origin.x = self.contentViewPhoto.frame.origin.x;
    imageFrame.origin.y = self.contentViewPhoto.frame.origin.y +
    self.collectionView.frame.origin.y + (IS_IPHONE_5 ? 44 : 22);
    
    CGRect r = [[UIScreen mainScreen] bounds];
    
    PhotoFullView *v = [[[NSBundle mainBundle] loadNibNamed:@"PhotoFullView"
                                                      owner:self options:nil]
                        objectAtIndex:0];
    v.user = self.user;
    v.delegate = self;
    [v loadPhotos];
    [self.navigationController.view addSubview:v];
    
    v.frame = CGRectMake(0, 20, r.size.width, r.size.height);
    v.pictureAnimation.frame = imageFrame;
    v.pictureAnimation.image = cell.imageView.image;
    [v.collectionView selectItemAtIndexPath:indexPath
                                   animated:NO
                             scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    [v refreshPageControl];
    [v show];
}

- (void)setRating:(NSInteger)rating
{
    for (int i = 1; i <= rating; i++)
    {
        UIImageView *star = (UIImageView *)[self.starContentView viewWithTag:i];
        [star setImage:[UIImage imageNamed:@"icon_star_fill.png"]];
    }
    
    self.notYetRatedLabel.hidden = rating > 0;
    self.starContentView.frame = CGRectSetY(self.starContentView.frame,
                                            rating > 0 ? 274 : 270);
}

- (BOOL)withOtherOffer
{
    return [self.user.lastOfferID intValue] > 0 && self.offer;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if ([self withOtherOffer])
    {
        CGFloat height = sizeWithText([self offerText:self.offer],
                                      self.text2Label.font,
                                      CGSizeMake(CGRectGetWidth(self.text2Label.frame),
                                                 9999)).height;
        self.text2Label.frame = CGRectSetHeight(self.text2Label.frame, height + 10);
        self.contentViewText2.frame = CGRectSetHeight
        (self.contentViewText2.frame, CGRectGetHeight(self.text2Label.frame) + 10);
        self.acceptedContentView.frame =
        CGRectSetHeight(self.acceptedContentView.frame,
                        CGRectGetHeight(self.contentViewText2.frame) + 59);
    }
    
    CGFloat y = CGRectGetMaxY(self.acceptedContentView.frame) +
    (self.acceptedContentView.isHidden ? -100 : -27);
    self.submitContentView.frame = CGRectSetY(self.submitContentView.frame, y);
    
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame),
                                             CGRectGetMaxY(self.submitContentView.frame) + 10);
}

- (void)updateSubmitButton
{
    self.submitButton.enabled = (self.textView.text.length > 0 &&
                                 self.textView.text.length <= 140);
    
    if (self.offer && !self.updateOffer)
    {
        User *current = [CoreDataHelper currentUser];
        self.submitButton.enabled = ![self.offer.senderUser.facebookID
                                      isEqualToString:current.facebookID];
    }
    
    self.submitButton.backgroundColor = self.submitButton.enabled ?
    RGBCOLOR(142, 135, 81) : [UIColor lightGrayColor];
}

- (void)fetchLastOffer
{
    Offer *offer = [CoreDataHelper fetchOfferWithId:[self.user.lastOfferID stringValue]];
    self.submitButton.enabled = NO;
    
    if (offer)
    {
        self.offer = offer;
        
        NSString *v = [Util timerTimeLeft:self.offer.timer];
        
        if (self.offer.timer.length && v.length && [self.offer.status integerValue] == OfferStatusAccepted)
        {
            [self refreshWithLastOffer:offer];
            [self updateSubmitButton];
        }
        else
        {
            self.offer = nil;
            
            NSManagedObjectContext *localContext = self.user.managedObjectContext;
            self.user.lastOfferID = @(-1);
            [localContext saveWithOptions:SaveParentContexts|SaveSynchronously
                               completion:nil];
            
            [self refreshWithoutLastOffer];
            self.submitButton.enabled = YES;
        }
    }
    else
    {
        __weak DateViewController *wself = self;
        
        [ApiHandler getOffer:[self.user.lastOfferID stringValue]
                      result:^(BOOL result)
         {
             if (wself)
             {
                 if (result)
                     [wself fetchLastOffer];
             }
         }];
    }
}

- (NSString *)offerText:(Offer *)offer
{
    return [NSString stringWithFormat:@"%@ proposed %@",
            [offer.senderUser fullName], offer.text];
}

- (void)refreshWithoutLastOffer
{
    self.timerContentView.hidden = YES;
    self.acceptedContentView.hidden = YES;
    self.offertHeaderLabel.text = @"Submit Your Date. Court them with Courtem!";
    [self.view setNeedsLayout];
}

- (void)refreshWithLastOffer:(Offer *)offer
{
    self.timerContentView.hidden = NO;
    self.acceptedContentView.hidden = NO;
    
    // Time left
    NSString *timeLabel = [Util timerTimeLeft:self.offer.timer];
    
    if (timeLabel)
        self.timeLabel.text = timeLabel;
    else
        self.timerContentView.hidden = YES;
    
    // Offer text
    self.text2Label.text = [self offerText:offer];
    [self.text2Label addCustomLink:[NSURL URLWithString:offer.senderUser.facebookID]
                           inRange:[self.text2Label.text
                                    rangeOfString:[offer.senderUser fullName]]];
    
    // Offer header
    self.offertHeaderLabel.text = @"Beat the Competition and Make Your Own Offer";
    
    [self.view setNeedsLayout];
}

- (void)showUser
{
    MyProfileViewController *vc = [[MyProfileViewController alloc]
                                   initWithNibName:@"MyProfileViewController" bundle:nil];
    vc.user = self.offer.senderUser;
    vc.isOtherProfile = YES;
    vc.fromDates = NO;
    vc.textTitle = NSLocalizedString(@"t_Profile", nil);
    
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    NSInteger count = self.arrayPhotos.count;
    self.pageControl.numberOfPages = count;
    self.pageControl.hidden = count <= 1;
    
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ProfileImagesGalleryCell *cell = (ProfileImagesGalleryCell *)
    [collectionView dequeueReusableCellWithReuseIdentifier:@"ProfileImagesGalleryCellId"
                                              forIndexPath:indexPath];
    
    [cell.imageView loadImageWithURL:((ProfilePictureUrl *)self.arrayPhotos[indexPath.row]).url];
    
    return cell;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat pageWidth = self.collectionView.frame.size.width;
    self.pageControl.currentPage = self.collectionView.contentOffset.x / pageWidth;
}

- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
{
    [self showPhotoFull:indexPath];
}

#pragma mark - OHAttributedLabelDelegate

- (BOOL)attributedLabel:(OHAttributedLabel *)attributedLabel
       shouldFollowLink:(NSTextCheckingResult *)linkInfo
{
    [self showUser];
    
    return NO;
}

#pragma mark - Notifications

- (void)textViewChange
{
    NSInteger value = 140 - (NSInteger)self.textView.text.length;
    self.countLabel.text = [@(value) stringValue];
    
    if (value >= 0)
        self.countLabel.textColor = [UIColor blackColor];
    else
        self.countLabel.textColor = [UIColor redColor];
    
    [self updateSubmitButton];
}

#pragma mark - Actions

- (IBAction)submitAction:(id)sender
{
    DateCalendarViewController *c = [[DateCalendarViewController alloc] initWithNibName:@"DateCalendarViewController" bundle:nil];
    c.delegate = self;
    c.user = self.user;
    c.offer = self.offer;
    c.offerText = self.textView.text;
    c.updateOffer = self.updateOffer;
    
    UINavigationController *n = [[UINavigationController alloc]
                                 initWithRootViewController:c];
    [self presentViewController:n animated:YES completion:nil];
}

- (void)backAction
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(dateCancel)])
    {
        [self.delegate dateCancel];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - PhotoFullDelegate

- (void)hidePhotoFull
{
    self.view.userInteractionEnabled = YES;
}

#pragma mark - DateCalendarDelegate

- (void)dateCalendarSubmit:(User *)user
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(dateSubmit:)])
        [self.delegate dateSubmit:user];
}

@end
