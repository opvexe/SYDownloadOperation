//
//  SYDownloader.m
//  SYDownloadOperation
//
//  Created by FaceBook on 2019/2/1.
//  Copyright © 2019年 FaceBook. All rights reserved.
//

#import "SYDownloader.h"
#import "SYCacheManger.h"
@implementation SYDownloader

+ (SYDownloader *)sharedDownloader{
    static dispatch_once_t onceToken;
    static id instance;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc]init];
    });
    return instance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _downloadBackgroundQueue = [[NSOperationQueue alloc]init];
        _downloadBackgroundQueue.name = @"com.background.downloader";
        _downloadBackgroundQueue.maxConcurrentOperationCount = 1;
        _downloadBackgroundQueue.qualityOfService = NSQualityOfServiceBackground;
        
        _downloadPriorityHighQueue = [[NSOperationQueue alloc]init];
        _downloadPriorityHighQueue.name = @"com.priorityhigh.downloader";
        _downloadPriorityHighQueue.maxConcurrentOperationCount = 1;
        _downloadBackgroundQueue.qualityOfService = NSQualityOfServiceUserInteractive;
        
         [_downloadPriorityHighQueue addObserver:self forKeyPath:@"operations" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}


-(SYCombineOperation *)downloadWithURL:(NSURL *)url
                        responseBlock:(SYDownloadResponseBlock)responseBlock
                         progressBlock:(SYDownloadProgressBlock)progressBlock
                        completedBlock:(SYDownloadCompletedBlock)completedBlock
                           cancelBlock:(SYDownloaderCancelBlock)cancelBlock
                          isBackground:(BOOL)isBackground{
    NSMutableURLRequest *requst = [[NSMutableURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15.0f];
    requst.HTTPShouldUsePipelining = NO;  ///NO: 响应得等到请求在处理
    
    __block NSString *key = url.absoluteString;
    __block SYCombineOperation *operation = [[SYCombineOperation alloc]init];
    __weak __typeof(self)wself = self;
    
    operation.cacheOperation = [[SYCacheManger sharedWebCache]queryDataFromMemory:key cacheQueryCompletedBlock:^(id data, BOOL hasCache) {
        if (hasCache) {
            if (completedBlock) {
                completedBlock(data,nil,YES);
            }
        }else{
            operation.downloadOperation = [[SYDownloadOperation alloc]initWithRequst:requst responseBlock:^(NSHTTPURLResponse *response) {
                if (responseBlock) {
                    responseBlock(response);
                }
            } downloadProgressBlock:progressBlock completeBlock:^(NSData *data, NSError *error, BOOL finished) {
                if (completedBlock) {
                    if (finished&&!error) {
                        [[SYCacheManger sharedWebCache] storeDataCache:data forKey:key];
                        completedBlock(data,nil,YES);
                    }else{
                        completedBlock(data,error,NO);
                    }
                }
            } cancelBlock:^{
                if (cancelBlock) {
                    cancelBlock();
                }
            }];
            if (isBackground) {
                [wself.downloadBackgroundQueue addOperation:operation.downloadOperation];
            }else{
                [wself.downloadPriorityHighQueue cancelAllOperations];
                [wself.downloadPriorityHighQueue addOperation:operation.downloadOperation];
            }
        }
    }];
    
    return operation;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"operations"]) {
        @synchronized (self) {
            if ([_downloadPriorityHighQueue.operations count] == 0) {
                [_downloadBackgroundQueue setSuspended:NO];
            } else {
                [_downloadBackgroundQueue setSuspended:YES];
            }
        }
    }else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc {
    [_downloadPriorityHighQueue removeObserver:self forKeyPath:@"operations"];
}


@end
