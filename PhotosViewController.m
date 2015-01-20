//
//  PhotosViewController.m
//  Courtem
//
//  Created by Eliezer de Armas on 08/05/14.
//  Copyright (c) 2014 MVD Forge. All rights reserved.
//

#import "PhotosViewController.h"
#import "FBAlbum.h"
#import "PhotoCell.h"
#import "CustomImageView.h"
#import "FacebookHandler.h"
#import "CoreDataHelper.h"
#import "FBPhoto.h"
#import "EditPhotoViewController.h"
#import "GKImageCropViewController.h"

@interface PhotosViewController () <GKImageCropControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) UIActivityIndicatorView *indicator;
@property (strong, nonatomic) NSArray *photos;

@end

@implementation PhotosViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Title
    self.title = self.album.name;
    
    // Register class
    [self.collectionView registerClass:[PhotoCell class] forCellWithReuseIdentifier:@"PhotoCell"];
    
    // Indicator
    self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self.indicator startAnimating];
    [self.collectionView addSubview:self.indicator];
    
    // Photos
    [self getPhotos];
//    self.photos = [CoreDataHelper fetchAllPhotosOfAlbum:self.album.albumID];
//    [self.indicator stopAnimating];
//    [self.collectionView reloadData];
}

- (void)dealloc
{
    self.indicator = nil;
    self.photos = nil;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.indicator.center = CGPointMake(CGRectGetWidth(self.collectionView.frame)/2 + 5,
                                        CGRectGetHeight(self.collectionView.frame)/2 - 22);
}

- (void)getPhotos
{
    __weak PhotosViewController *wself = self;
    
    [FacebookHandler getPhotosOfAlbum:self.album.albumID resultBloq:^(BOOL result)
     {
         if (result)
         {
             if (wself)
             {
                 wself.photos = [CoreDataHelper fetchAllPhotosOfAlbum:wself.album.albumID];
                 
                 dispatch_async(dispatch_get_main_queue(), ^(void) {
                     [wself.indicator stopAnimating];
                     [wself.collectionView reloadData];
                 });
             }
         }
     }];
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return self.photos.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FBPhoto *photo = self.photos[indexPath.row];
    
    PhotoCell *cell =
    [collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCell"
                                              forIndexPath:indexPath];
    [cell.picture loadImageWithURL:[NSURL URLWithString:photo.thumb]
                       placeholder:nil
                            resize:NO
                       successBloq:
     ^{
         cell.userInteractionEnabled = YES;
     }];
    
    cell.userInteractionEnabled = cell.picture.image != nil;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
{
    PhotoCell *cell = (PhotoCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    cell.picture.overlay.hidden = NO;
    [cell.picture.activityIndicator startAnimating];
    self.collectionView.userInteractionEnabled = NO;
    
    FBPhoto *photo = self.photos[indexPath.row];
    __weak PhotosViewController *wself = self;
    
    [ApiHandler getImage:photo.photoUrl responseBlock:^(UIImage *image)
    {
        if (wself)
        {
            wself.collectionView.userInteractionEnabled = YES;
            [cell.picture.activityIndicator stopAnimating];
            cell.picture.overlay.hidden = YES;
            
            if (image)
            {
                EditPhotoViewController *c = [[EditPhotoViewController alloc]
                                              initWithNibName:@"EditPhotoViewController"
                                              bundle:nil];
                c.delegate = wself;
                c.sourceImage = image;
                c.cropSize = CGSizeMake(310, 280);
                c.view.frame = wself.navigationController.view.frame;
                c.view.alpha = 0;
                [wself.navigationController addChildViewController:c];
                [wself.navigationController.view addSubview:c.view];
                [c show];
            }
            else
            {
                showConnectionError();
            }
        }
    }];
}

#pragma mark - GKImageCropControllerDelegate

- (void)imageCropController:(GKImageCropViewController *)imageCropController didFinishWithCroppedImage:(UIImage *)croppedImage
{
    [self.delegate selectedPhotos:@[croppedImage]];
}

@end
