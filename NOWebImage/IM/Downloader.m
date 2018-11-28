//
//  WebImageDownloader.m
//  WebImage
//
//  Created by 董子江 on 2018/11/22.
//  Copyright © 2018 nightowl. All rights reserved.
//

#import "Downloader.h"

@interface Downloader ()

@end

@implementation Downloader

+ (nonnull instancetype)sharedDownloader {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

-(void)loadWithURL:(NSURL*)url{
    
    
    dispatch_queue_t globalQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);//获取全局并行列队

//    执行异步任务
    dispatch_async(globalQ, ^{
        //任务
        if (!url) {
            return ;
        }
        NSData *imageData= [NSData dataWithContentsOfURL:url];
        
        if (imageData != nil) {
            //发送通知
            NSDictionary *dic = [[NSDictionary alloc]initWithObjects:@[imageData] forKeys:@[url]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"download_success" object:self userInfo:dic];
        } else {
            //发送通知
            NSDictionary *dic = [[NSDictionary alloc]initWithObjects:@[@""] forKeys:@[url]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"download_fail" object:self userInfo:dic];
        }
       
        
    });
    
}

@end
