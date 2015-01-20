//
//  ChatViewController.h
//  Courtem
//
//  Created by Eliezer de Armas on 30/03/14.
//  Copyright (c) 2014 MVD Forge. All rights reserved.
//

#import "BaseViewController.h"

@class User, ChatRoom;

@interface ChatViewController : BaseViewController

@property (nonatomic, strong) ChatRoom *chatRoom;

@end
