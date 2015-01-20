//
//  AlbumsViewController.h
//  Courtem
//
//  Created by Eliezer de Armas on 08/05/14.
//  Copyright (c) 2014 MVD Forge. All rights reserved.
//

#import "BaseViewController.h"

@protocol AlbumsDelegate <NSObject>

- (void)albumsSelectedImages:(NSArray *)images
                contentIndex:(NSInteger)contentIndex;

@end

@interface AlbumsViewController : BaseViewController

@property (nonatomic, weak) id<AlbumsDelegate> delegate;
@property (nonatomic, assign) NSInteger photoContentIndex;

@end
