//
//  PhotosViewController.h
//  Courtem
//
//  Created by Eliezer de Armas on 08/05/14.
//  Copyright (c) 2014 MVD Forge. All rights reserved.
//

#import "BaseViewController.h"

@class FBAlbum;

@protocol PhotosDelegate <NSObject>

- (void)selectedPhotos:(NSArray *)photos;

@end

@interface PhotosViewController : BaseViewController

@property (nonatomic, weak) FBAlbum *album;
@property (nonatomic, weak) id<PhotosDelegate> delegate;

@end
