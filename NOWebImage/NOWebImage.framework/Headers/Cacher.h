//
//  WebImageCache.h
//  WebImage
//
//  Created by 董子江 on 2018/11/22.
//  Copyright © 2018 nightowl. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Cacher : NSObject
+ (nonnull instancetype)sharedCacher;
- (void)saveImageToCache:(nullable NSData *)imageData forURL:(nullable NSURL *)url;
-(NSData *)readImageToCacheWithURL:(nullable NSURL *)url;
@end

NS_ASSUME_NONNULL_END
