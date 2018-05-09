//
//  ZOSSFileUploader.h
//  ZOSSFileUploader
//
//  Created by zwx on 2017/12/14.
//  Copyright © 2017年 zwx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AliyunOSSiOS/OSSService.h>


@interface ZOSSFileUploader : NSObject

+(instancetype) shareInstance;


+(NSString*) aliUrlWithName:(NSString*)name;


//progress、complete 回调 都已切换至主线程
// names  返回阿里云 图片的 后缀名
- (void)asyncUploadImages:(NSArray<UIImage *> *)images
                 progress:(void(^)(int64_t byteSent, int64_t bytesTotal, double progress))progress
                 complete:(void(^)(NSArray<NSString *> *names, BOOL isSuccess))complete;

- (void)asyncUploadDatas:(NSArray<NSData *> *)datas
                progress:(void(^)(int64_t byteSent, int64_t bytesTotal, double progress))progress
                complete:(void(^)(NSArray<NSString *> *names, BOOL isSuccess))complete;

- (void)asyncUploadPaths:(NSArray<NSString *> *)paths
                progress:(void(^)(int64_t byteSent, int64_t bytesTotal, double progress))progress
                complete:(void(^)(NSArray<NSString *> *names, BOOL isSuccess))complete;



@end
