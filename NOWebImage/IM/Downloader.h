//
//  WebImageDownloader.h
//  WebImage
//
//  Created by 董子江 on 2018/11/22.
//  Copyright © 2018 nightowl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Cacher.h"

NS_ASSUME_NONNULL_BEGIN

@interface Downloader : NSObject
+ (nonnull instancetype)sharedDownloader;
-(void)loadWithURL:(NSURL*)url;
@end

NS_ASSUME_NONNULL_END
