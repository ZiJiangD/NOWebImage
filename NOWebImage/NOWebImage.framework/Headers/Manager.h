//
//  WebImageManager.h
//  WebImage
//
//  Created by 董子江 on 2018/11/22.
//  Copyright © 2018 nightowl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Cacher.h"
#import "Downloader.h"
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface Manager : NSObject
+ (nonnull instancetype)sharedManager;
-(void)setImage:(UIImageView*)imageV withURL:(nullable NSURL *)url;
@end

NS_ASSUME_NONNULL_END
