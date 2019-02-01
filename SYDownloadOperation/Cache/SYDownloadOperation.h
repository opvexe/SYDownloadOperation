//
//  SYDownloadOperation.h
//  SYDownloadOperation
//
//  Created by FaceBook on 2019/2/1.
//  Copyright © 2019年 FaceBook. All rights reserved.
//

#import <Foundation/Foundation.h>

///MARK: 下载相应回调
typedef void (^SYDownloadResponseBlock)(NSHTTPURLResponse *response);

///MARK: 下载进度回调
typedef void (^SYDownloadProgressBlock)(NSInteger receivedSize, NSInteger expectedSize, NSData *data);

///MARK: 下载完毕回到
typedef void(^SYDownloadCompletedBlock)(NSData *data, NSError *error, BOOL finished);

///MARK: 取消下载回调
typedef void (^SYDownloaderCancelBlock)(void);

NS_ASSUME_NONNULL_BEGIN
/*
 * 下载网络资源队列类
 */
@interface SYDownloadOperation : NSOperation<NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

///MARK:网络请求类
@property(nonatomic,strong)NSURLSession *session;

///MARK: 网络请求挂起
@property(nonatomic,strong)NSURLSessionTask *task;

///MARK: 请求
@property(nonatomic,strong)NSURLRequest *requst;

-(instancetype)initWithRequst:(NSURLRequest *)requst responseBlock:(SYDownloadResponseBlock)responseBlock downloadProgressBlock:(SYDownloadProgressBlock)progressBlock completeBlock:(SYDownloadCompletedBlock)completeBlock cancelBlock:(SYDownloaderCancelBlock)cancelBlock;

@end

NS_ASSUME_NONNULL_END
