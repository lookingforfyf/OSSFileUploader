//
//  ZOSSFileUploader.m
//  ZOSSFileUploader
//
//  Created by zwx on 2017/12/14.
//  Copyright © 2017年 zwx. All rights reserved.
//

#import "ZOSSFileUploader.h"

static NSString *const AccessKey = @"LTAIwQU3aCce2JVt";
static NSString *const SecretKey = @"N8qQ8nVlTlUIVmpMH8773VAuHoAkjI";
static NSString *const BucketName = @"yryz-circle";
static NSString *const AliYunHost = @"http://oss-cn-hangzhou.aliyuncs.com/";
static NSString *kTempFolder = @"vedio";



@interface ZOSSFileUploader()


@property (nonatomic,strong) OSSClient * o_client;

@property (nonatomic,strong) dispatch_group_t o_group;
@property (nonatomic,strong) dispatch_queue_t o_concurrently_Queue;

//采用 保存文件的方式
@property (nonatomic,strong) NSMutableArray* o_filePathArr;//临时缓存文件路径

@property (nonatomic,strong) NSMutableArray* o_aliFileNameArr;//阿里 文件路径后缀名

@property (assign) int64_t o_totalSent;//总发送进度
@property (assign) int64_t o_totalBytes;//总字节数

@property (nonatomic,assign) BOOL o_isError;

@end



@implementation ZOSSFileUploader

+(instancetype) shareInstance
{
    static ZOSSFileUploader* _upload = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _upload = [[ZOSSFileUploader alloc] init];
    });
    return _upload;
}


+(NSString*) aliUrlWithName:(NSString*)name
{
    NSString* fullStr = [NSString stringWithFormat:@"https://%@.%@/%@",BucketName,[[NSURL URLWithString:AliYunHost] host],name];
    return fullStr;
}

- (void)asyncUploadImages:(NSArray<UIImage *> *)images
                    datas:(NSArray<NSData *> *)datas
                    paths:(NSArray<NSString *> *)paths
                 progress:(void(^)(int64_t byteSent, int64_t bytesTotal, double progress))progress
                 complete:(void(^)(NSArray<NSString *> *names, BOOL isSuccess))complete
{
    if (images.count <= 0 && datas.count <= 0 && paths.count <= 0) {
        if (complete) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                complete(nil,NO);
            });
        }
        return;
    }
    
    _o_group = dispatch_group_create();
    _o_concurrently_Queue = dispatch_queue_create("com.concurrently.ZOSSImageUplpader", DISPATCH_QUEUE_CONCURRENT);
    
    _o_totalSent = 0;
    _o_totalBytes = 0;
    _o_isError = NO;
    
    _o_aliFileNameArr = [NSMutableArray array];
    _o_filePathArr = [NSMutableArray array];
    
    id<OSSCredentialProvider> credential = [[OSSPlainTextAKSKPairCredentialProvider alloc] initWithPlainTextAccessKey:AccessKey                                                                                                            secretKey:SecretKey];
    _o_client = [[OSSClient alloc] initWithEndpoint:AliYunHost credentialProvider:credential];
    
    
    __weak typeof(self) weakself = self;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        BOOL isImage = YES,isData = NO,isPath = NO;
        NSArray* newDataArr = images;
        if (datas.count > 0) {
            newDataArr = datas;
            isImage = NO;
            isData = YES;
            isPath = NO;
        }else if (paths.count > 0){
            newDataArr = paths;
            isImage = NO;
            isData = NO;
            isPath = YES;
        }
        
        
        //计算 总上传大小、 上传到阿里的文件名、保存在本地目录地址(方便后续删除)
        for (NSInteger i=0; i<newDataArr.count; i++) {
            
            id vObject = [newDataArr objectAtIndex:i];
            
            if ([vObject isKindOfClass:[UIImage class]]) {
                
                UIImage* image = vObject;
                
                NSString* fileName = [[NSUUID UUID].UUIDString stringByAppendingString:@".jpg"];
                NSString *imageName = fileName;
                if (kTempFolder.length > 0) {
                    imageName = [kTempFolder stringByAppendingPathComponent:fileName];
                }
                [weakself.o_aliFileNameArr addObject:imageName];
                
                NSData *data = UIImageJPEGRepresentation(image, 0.8);//0.8 失真程度小
                weakself.o_totalBytes += [data length];
                NSString* tPath = [ZOSSFileUploader saveData:data fileName:fileName];
                [weakself.o_filePathArr addObject:tPath];
                
            }else if ([vObject isKindOfClass:[NSData class]]) {
                
                NSData* data = vObject;
                
                NSString* fileName = [NSUUID UUID].UUIDString;
                NSString *imageName = fileName;
                if (kTempFolder.length > 0) {
                    imageName = [kTempFolder stringByAppendingPathComponent:fileName];
                }
                [weakself.o_aliFileNameArr addObject:imageName];
                
                weakself.o_totalBytes += [data length];
                
                NSString* tPath = [ZOSSFileUploader saveData:data fileName:fileName];
                [weakself.o_filePathArr addObject:tPath];
            }else if ([vObject isKindOfClass:[NSString class]]) {
                
                NSString* path = vObject;
                
                NSString* fileName = [NSUUID UUID].UUIDString;
                fileName = [fileName stringByAppendingString:@"-"];
                fileName = [fileName stringByAppendingString:[path lastPathComponent]];
                NSString *imageName = fileName;
                if (kTempFolder.length > 0) {
                    imageName = [kTempFolder stringByAppendingPathComponent:fileName];
                }
                [weakself.o_aliFileNameArr addObject:imageName];
                
                weakself.o_totalBytes += [ZOSSFileUploader getFileSizeWithPath:path];
                
//                NSString* tPath = [weakself saveData:data fileName:fileName];
                [weakself.o_filePathArr addObject:path];
            }
                
            
        }
        
        for (NSInteger i=0; i<newDataArr.count; i++) {
            
            dispatch_group_async(_o_group, _o_concurrently_Queue, ^{
                
                //任务执行
                OSSPutObjectRequest * put = [OSSPutObjectRequest new];
                put.bucketName = BucketName;
                put.objectKey = [weakself.o_aliFileNameArr objectAtIndex:i];
                put.uploadingFileURL = [NSURL fileURLWithPath:[weakself.o_filePathArr objectAtIndex:i]];
                /******* 规避阿里云 使用 NSData的方式 上传（引起内存泄露） *******/
//                put.uploadingData = [weakself.o_dataArr objectAtIndex:i];
                
                put.uploadProgress = ^(int64_t bytesSent, int64_t totalByteSent, int64_t totalBytesExpectedToSend) {
                    
                    //总已发送 字节数增加
                    weakself.o_totalSent += bytesSent;
                    
                    NSLog(@" %lld, %lld, --%lf",weakself.o_totalSent, weakself.o_totalBytes,(1.0*weakself.o_totalSent)/weakself.o_totalBytes);
                    
                    if (progress) {
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            progress(weakself.o_totalSent,weakself.o_totalBytes,(1.0*weakself.o_totalSent)/weakself.o_totalBytes);
                        });
                    }
                };
                
                OSSTask * putTask = [weakself.o_client putObject:put];
                [putTask waitUntilFinished]; // 阻塞直到上传完成
                put = nil;
                if (!putTask.error) {
                    NSLog(@"upload object success!");
                } else {
                    NSLog(@"upload object failed, error: %@" , putTask.error);
                    weakself.o_isError = YES;
                }
                
            });
        }
        
        //异步等待所有 任务结束 通知
        dispatch_group_notify(_o_group, _o_concurrently_Queue, ^{
            
            if (isData || isImage) {
                [weakself cleanCacheFiles];
            }
            [weakself cleanObjectCache];
            
            if (complete) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    NSLog(@" Is success ----%@---",!weakself.o_isError?@"YES":@"NO");
                    complete(weakself.o_aliFileNameArr,!weakself.o_isError);
                });
            }
            
        });
        
    });
}




- (void)asyncUploadImages:(NSArray<UIImage *> *)images
                 progress:(void(^)(int64_t byteSent, int64_t bytesTotal, double progress))progress
                 complete:(void(^)(NSArray<NSString *> *names, BOOL isSuccess))complete
{
    [self asyncUploadImages:images datas:nil paths:nil progress:progress complete:complete];
    
}


- (void)asyncUploadDatas:(NSArray<NSData *> *)datas
                progress:(void(^)(int64_t byteSent, int64_t bytesTotal, double progress))progress
                complete:(void(^)(NSArray<NSString *> *names, BOOL isSuccess))complete
{
    [self asyncUploadImages:nil datas:datas paths:nil progress:progress complete:complete];
}

- (void)asyncUploadPaths:(NSArray<NSString *> *)paths
                progress:(void(^)(int64_t byteSent, int64_t bytesTotal, double progress))progress
                complete:(void(^)(NSArray<NSString *> *names, BOOL isSuccess))complete
{
    [self asyncUploadImages:nil datas:nil paths:paths progress:progress complete:complete];
}



#pragma mark-

-(void) cleanObjectCache
{
    __weak typeof(self) weakself = self;
    weakself.o_client = nil;
    
    weakself.o_group = nil;
    weakself.o_concurrently_Queue = nil;
}

-(void) cleanCacheFiles
{
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        for (NSString* filePath in weakself.o_filePathArr) {
            [[weakself class] removeFileWithPath:filePath];
        }
        [weakself.o_filePathArr removeAllObjects];
        weakself.o_filePathArr = nil;
        
    });
}


#pragma mark- 文件操作

+ (NSString *) cachesPath
{
    return [self pathForDirectory:NSCachesDirectory];
}

+ (NSString *)pathForDirectory:(NSSearchPathDirectory)directory
{
    return [NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES) firstObject];
}


/**
 * 删除文件、文件夹
 */
+(BOOL) removeFileWithPath:(NSString *)path
{
    return [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}


/**
 * 获取文件大小
 */
+(long long) getFileSizeWithPath:(NSString *)Path
{
    NSFileManager *fm  = [NSFileManager defaultManager];
    
    // 取文件大小
    NSError *error = nil;
    NSDictionary* dictFile = [fm attributesOfItemAtPath:Path error:&error];
    if (error)
    {
        NSLog(@"getfilesize error: %@", error);
        return -1;
    }
    long long nFileSize = [dictFile fileSize]; //得到文件大小
    
    return nFileSize;
}


+(NSString*) saveData:(NSData*)data fileName:(NSString*)fileName
{
    NSString *cache_document = [self cachesPath];
    //设置一个图片的存储路径
    NSString *imagePath = [cache_document stringByAppendingPathComponent:fileName];
    //把图片直接保存到指定的路径（同时应该把图片的路径imagePath存起来，下次就可以直接用来取）
    [data writeToFile:imagePath atomically:YES];
    
    return imagePath;
}

@end
