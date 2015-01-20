//
//  DateViewController.h
//  Courtem
//
//  Created by Eliezer de Armas on 27/03/14.
//  Copyright (c) 2014 MVD Forge. All rights reserved.
//

#import "BaseViewController.h"

@class User, Offer;

@protocol DateDelegate <NSObject>

@optional
- (void)dateCancel;
- (void)dateSubmit:(User *)user;

@end

@interface DateViewController : BaseViewController

@property (assign, nonatomic) BOOL fromProfile;
@property (strong, nonatomic) User *user;
@property (weak, nonatomic) id<DateDelegate> delegate;
@property (strong, nonatomic) Offer *offer;
@property (assign, nonatomic) BOOL updateOffer;

@end
