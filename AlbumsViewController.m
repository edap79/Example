//
//  AlbumsViewController.m
//  Courtem
//
//  Created by Eliezer de Armas on 08/05/14.
//  Copyright (c) 2014 MVD Forge. All rights reserved.
//

#import "AlbumsViewController.h"
#import "AlbumCell.h"
#import "FacebookHandler.h"
#import "CoreDataHelper.h"
#import "FBAlbum.h"
#import "CustomImageView.h"
#import "PhotosViewController.h"

@interface AlbumsViewController () <UITableViewDataSource, UITableViewDelegate,
PhotosDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UIActivityIndicatorView *indicator;
@property (strong, nonatomic) NSArray *albums;

@end

@implementation AlbumsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Titile
    [self setTitle:NSLocalizedString(@"t_Albums", nil)];
    
    // Cancel item
    self.navigationItem.leftBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain
                                    target:self action:@selector(cancelAction)];
    
    // Nibs
    NSBundle *classBundle = [NSBundle bundleForClass:[AlbumCell class]];
    UINib *nib = [UINib nibWithNibName:@"AlbumCell" bundle:classBundle];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"AlbumCell"];
    
    // Indicator
    self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self.indicator startAnimating];
    [self.tableView addSubview:self.indicator];
    
    // Albums
    [self getAlbums];
}

- (void)dealloc
{
    self.indicator = nil;
    self.albums = nil;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.indicator.center = CGPointMake(CGRectGetWidth(self.tableView.frame)/2 + 5,
                                        CGRectGetHeight(self.tableView.frame)/2 - 22);
}

- (void)getAlbums
{
    __weak AlbumsViewController *wself = self;
    
    [FacebookHandler getAlbums:^(BOOL result)
     {
         if (result)
         {
             if (wself)
             {
                 wself.albums = [CoreDataHelper fetchAllAlbums];
                 
                 dispatch_async(dispatch_get_main_queue(), ^(void) {
                     [wself.indicator stopAnimating];
                     [wself.tableView reloadData];
                 });
             }
         }
     }];
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.albums.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AlbumCell"];
    
    FBAlbum *album = self.albums[indexPath.row];
    cell.albumName.text = album.name;
    cell.photosCount.text = [NSString stringWithFormat:@"%d photos", [album.count intValue]];
    [cell.picture loadImageWithURL:[FacebookHandler coverAlbumUrl:album.coverPhoto]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PhotosViewController *c = [[PhotosViewController alloc]
                              initWithNibName:@"PhotosViewController"
                              bundle:nil];
    c.delegate = self;
    c.album = self.albums[indexPath.row];
    [self.navigationController pushViewController:c animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Actions

- (void)cancelAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - PhotosDelegate

- (void)selectedPhotos:(NSArray *)photos
{
    [self.delegate albumsSelectedImages:photos contentIndex:self.photoContentIndex];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
