//
//  ZZViewController.h
//  ShareLocation
//
//  Created by zhuzhi on 13-8-29.
//  Copyright (c) 2013年 ZZ. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FSVenue;

@protocol ShareLocationDelegate;

@interface ZZViewController : UIViewController

@property(nonatomic,weak)id<ShareLocationDelegate>delegate;

@end

@protocol ShareLocationDelegate <NSObject>

-(void)didSelectVenue:(FSVenue *)venue;

@end