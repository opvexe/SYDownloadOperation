//
//  SYDownloader.h
//  SYDownloadOperation
//
//  Created by FaceBook on 2019/2/1.
//  Copyright © 2019年 FaceBook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SYDownloadOperation.h"
#import "SYCombineOperation.h"
NS_ASSUME_NONNULL_BEGIN

/*
 * 下载管理类
 */
@interface SYDownloader : NSObject
@property (strong, nonatomic) NSOperationQueue *downloadBackgroundQueue;
@property (strong, nonatomic) NSOperationQueue *downloadPriorityHighQueue;
+ (SYDownloader *)sharedDownloader;

-(SYCombineOperation *)downloadWithURL:(NSURL *)url
                         responseBlock:(SYDownloadResponseBlock)responseBlock
                         progressBlock:(SYDownloadProgressBlock)progressBlock
                        completedBlock:(SYDownloadCompletedBlock)completedBlock
                           cancelBlock:(SYDownloaderCancelBlock)cancelBlock
                            isBackground:(BOOL)isBackground;
@end

NS_ASSUME_NONNULL_END
