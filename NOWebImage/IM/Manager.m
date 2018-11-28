//
//  WebImageManager.m
//  WebImage
//
//  Created by 董子江 on 2018/11/22.
//  Copyright © 2018 nightowl. All rights reserved.
//

#import "Manager.h"

#define LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#define UNLOCK(lock) dispatch_semaphore_signal(lock);
@interface Manager ()

/**
 正在请求 ImageView y与URL 的对应关系
 */
@property (nonatomic ,strong)NSMutableDictionary *imgV_url_dic;
@property (strong, nonatomic, nonnull) dispatch_queue_t serialQueue;
@end
@implementation Manager
+ (nonnull instancetype)sharedManager {
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
        self.imgV_url_dic=[[NSMutableDictionary alloc]init];
        self.serialQueue= dispatch_queue_create("串行队列", DISPATCH_QUEUE_SERIAL);
        
        [[NSNotificationCenter defaultCenter] addObserverForName:@"download_success" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            NSLog(@"收到通知，下载成功");
            [self downLoadSuccessDic:note.userInfo];
            
        }];
        [[NSNotificationCenter defaultCenter] addObserverForName:@"download_fail" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            NSLog(@"收到通知，下载失败");
            [self downLoadFail:note.userInfo];
        }];
        [[NSNotificationCenter defaultCenter] addObserverForName:@"readCache_success" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            NSLog(@"收到通知，读取内存成功");
            [self readCacheSuccessDic:note.userInfo];
            
        }];
        
        
    }
    return self;
}

-(void)setImage:(UIImageView*)imageV withURL:(nullable NSURL *)url{
    

    static NSInteger isHad;
    
    //crate的value表示，最多几个资源可访问
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);

    //任务1
    dispatch_async(_serialQueue, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        isHad = [self saveTempImgV_url_dicImageV:imageV andUrl:url];
        dispatch_semaphore_signal(semaphore);
    });
    //任务2
    dispatch_async(_serialQueue, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        if (isHad!=0){//临时url 存在
            //从cacher读取
            NSData *tempData=[[Cacher sharedCacher] readImageToCacheWithURL:url];
            if (tempData != nil) {
                [self updateImageView:tempData andImageUrl:url];
                
            }else{
                [[Downloader sharedDownloader] loadWithURL:url];
            }
        }else{
            [[Downloader sharedDownloader] loadWithURL:url];
        }
        dispatch_semaphore_signal(semaphore);
    });
    
    
    
    
}



/**
 保存临时Imageview 对应 Url 的 对应  并且 查询是否存在Url

 @param imgV imageView
 @param url url
 @return return value 是否已经存在 url
 */
-(NSInteger)saveTempImgV_url_dicImageV:(UIImageView *)imgV andUrl:(NSURL *)url {
    
    NSLog(@"saveTempImgV_url_dicImageV");
    //
    if ([[self.imgV_url_dic allKeys] containsObject:url]) {
        NSMutableArray *imgVList=(NSMutableArray *)[self.imgV_url_dic objectForKey:url];
        
        NSMutableArray *m_list=[[NSMutableArray alloc]initWithArray:imgVList];
        [m_list addObject:imgV];
        [self.imgV_url_dic setObject:m_list forKey:url];
        
        return 2;
    } else {
        if ([[Cacher sharedCacher]readImageToCacheWithURL:url] != nil) {
            [self.imgV_url_dic setObject:@[imgV] forKey:url];
            return 1;
        } else {
            [self.imgV_url_dic setObject:@[imgV] forKey:url];
            return 0;
        }

    }
}


/**
 删除临时Imageview 对应 Url 的 d对应

 @param url url
 */
-(void)deleteTempImgV_url_dicUrl:(NSURL *)url andImageView:(UIImageView *)imgV{
    NSArray *list=[self.imgV_url_dic objectForKey:url];
    NSMutableArray *m_list=[[NSMutableArray alloc]initWithArray:list];
    [m_list removeObject:imgV];
    [self.imgV_url_dic setObject:m_list forKey:url];
}





/**
 下载失败

 @param dic {imageData:url}
 */
-(void)downLoadFail:(NSDictionary*)dic{
    NSLog(@"downLoadFail");
    
}


/**
 下载成功

 @param dic {imageData:url}
 */
-(void)downLoadSuccessDic:(NSDictionary*)dic{
    dispatch_queue_t globalQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);//获取全局并行列队
    //    执行异步任务
    NSURL *key=[dic allKeys][0];
    NSData *value=(NSData*)[dic objectForKey:key];
    dispatch_async(globalQ, ^{
        //存
        [[Cacher sharedCacher] saveImageToCache:value forURL:key];
        //更新UI
        [self updateImageView:value andImageUrl:key];
    });
}



-(void)readCacheSuccessDic:(NSDictionary*)dic{
    dispatch_queue_t globalQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);//获取全局并行列队
    //    执行异步任务
    NSURL *key=[dic allKeys][0];
    NSData *value=(NSData*)[dic objectForKey:key];
    dispatch_async(globalQ, ^{
        //存
        [[Cacher sharedCacher] saveImageToCache:value forURL:key];
        //更新UI
        [self updateImageView:value andImageUrl:key];
        
    });
}
-(void)readCache_faileUrl:(NSURL *)url{
    
}
/**
 更新ImageView

 @param imageData imageData
 @param url imageView 的url
 */
-(void)updateImageView:(NSData *)imageData andImageUrl:(NSURL *)url{
    dispatch_queue_t mainQueue = dispatch_get_main_queue();//获取主线列队

    NSArray *list=[self.imgV_url_dic objectForKey:url];
    UIImage *img=[[UIImage alloc]initWithData:imageData];
    UIImageView *imgV=[list firstObject];
    dispatch_async(mainQueue, ^{
      
        imgV.image=img;
        
    });
    
    [self deleteTempImgV_url_dicUrl:url andImageView:imgV];
}
@end
