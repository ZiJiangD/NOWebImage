//
//  WebImageCache.m
//  WebImage
//
//  Created by 董子江 on 2018/11/22.
//  Copyright © 2018 nightowl. All rights reserved.
//

#import "Cacher.h"
#import "zlib.h"

@interface Cacher ()
{
    NSMutableDictionary *catchDic;
}
@end

@implementation Cacher

+ (nonnull instancetype)sharedCacher {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        catchDic = [[NSMutableDictionary alloc]init];
    }
    return self;
}

- (void)saveImageToCache:(nullable NSData *)imageData forURL:(nullable NSURL *)url{
    //
    NSData *deflateData = [self gzipDeflate:imageData];
//    [catchDic setValue:deflateData forKey:url.absoluteString];
    //存于内存
    [catchDic setObject:deflateData forKey:url];
    //存于磁盘
    NSString *cachesDirectory=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSLog(@"%@",cachesDirectory);
    
}
-(NSData *)readImageToCacheWithURL:(nullable NSURL *)url{
//    NSLog(@"readImageToCacheWithURLreadImageToCacheWithURL");
    
    if ([[catchDic allKeys]containsObject:url] ) {
        NSData * valueData=[catchDic objectForKey:url];
        NSData * inFlateData=[self gzipInflate:valueData];
        return inFlateData;
    }else{
        dispatch_queue_t globalQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);//获取全局并行列队
        //    执行异步任务
        dispatch_async(globalQ, ^{
            //读取磁盘 存储
            NSURLCache *cache=[NSURLCache sharedURLCache];
//            NSLog(@"cache %@",cache);
            NSURLRequest * request=[[NSURLRequest alloc]initWithURL:url];
//            NSLog(@"request %@",request);
            NSCachedURLResponse * response=[cache cachedResponseForRequest:request];
            //发送通知 存储于内存
            @try {
                NSDictionary *dic = [[NSDictionary alloc]initWithObjects:@[[response data]] forKeys:@[url]];
//                NSLog(@"============%@",dic);
                [[NSNotificationCenter defaultCenter] postNotificationName:@"readCache_success" object:self userInfo:dic];
            } @catch (NSException *exception) {
//                NSLog(@"%@",exception);
//                [[NSNotificationCenter defaultCenter] postNotificationName:@"readCache_faile" object:self userInfo:dic];
            } @finally {
                
            }
            
        });
    }
    
    
    return nil;
}


//压缩
- (NSData *)gzipDeflate:(NSData*)data
{
    if ([data length] == 0) return data;
    
    z_stream strm;
    
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.total_out = 0;
    strm.next_in=(Bytef *)[data bytes];
    strm.avail_in = (uInt)[data length];
    
    // Compresssion Levels:
    //   Z_NO_COMPRESSION
    //   Z_BEST_SPEED
    //   Z_BEST_COMPRESSION
    //   Z_DEFAULT_COMPRESSION
    
    if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) return nil;
    
    NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chunks for expansion
    
    do {
        
        if (strm.total_out >= [compressed length])
            [compressed increaseLengthBy: 16384];
        
        strm.next_out = [compressed mutableBytes] + strm.total_out;
        strm.avail_out = (uInt)([compressed length] - strm.total_out);
        
        deflate(&strm, Z_FINISH);
        
    } while (strm.avail_out == 0);
    
    deflateEnd(&strm);
    
    [compressed setLength: strm.total_out];
    return [NSData dataWithData:compressed];
}


//解压缩
- (NSData *)gzipInflate:(NSData*)data
{
    if ([data length] == 0) return data;
    
    unsigned long full_length = [data length];
    unsigned long  half_length = [data length] / 2;
    
    NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
    BOOL done = NO;
    int status;
    
    z_stream strm;
    strm.next_in = (Bytef *)[data bytes];
    strm.avail_in = (uInt)[data length];
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    
    if (inflateInit2(&strm, (15+32)) != Z_OK)
        return nil;
    
    while (!done)
    {
        // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= [decompressed length])
            [decompressed increaseLengthBy: half_length];
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = (uInt)([decompressed length] - strm.total_out);
        
        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END)
            done = YES;
        else if (status != Z_OK)
            break;
    }
    if (inflateEnd (&strm) != Z_OK)
        return nil;
    
    // Set real length.
    if (done)
    {
        [decompressed setLength: strm.total_out];
        return [NSData dataWithData: decompressed];
    }
    else return nil;
}
@end
