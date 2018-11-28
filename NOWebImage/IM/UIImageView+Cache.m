//
//  UIImageView+Cache.m
//  OwlWebImage
//
//  Created by 董子江 on 2018/11/26.
//  Copyright © 2018 nightowl. All rights reserved.
//

#import "UIImageView+Cache.h"
#import "Manager.h"

@implementation UIImageView (Cache)
-(void)dj_setImageWithURL:(NSURL *)url{
    [[Manager sharedManager] setImage:self withURL:url];
}
@end
