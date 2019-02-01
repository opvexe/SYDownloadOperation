//
//  SYDownloadOperation.m
//  SYDownloadOperation
//
//  Created by FaceBook on 2019/2/1.
//  Copyright © 2019年 FaceBook. All rights reserved.
//

#import "SYDownloadOperation.h"
@interface SYDownloadOperation()
@property(nonatomic,copy)SYDownloaderCancelBlock cancelBlock;
@property(nonatomic,copy)SYDownloadCompletedBlock completeBlock;
@property(nonatomic,copy)SYDownloadProgressBlock progressBlock;
@property(nonatomic,copy)SYDownloadResponseBlock responseBlock;
@property(nonatomic,strong)NSMutableData *data; ///MARK: 下载网络数据
@property(nonatomic,assign)NSInteger expectedSize; ///MARK:网络资源总大小
@property(nonatomic,assign)BOOL executing;//MARK:队列执行
@property(nonatomic,assign)BOOL finished; ///MARK:队列结束
@end
@implementation SYDownloadOperation
@synthesize executing = _executing;
@synthesize finished = _finished;

-(instancetype)initWithRequst:(NSURLRequest *)requst responseBlock:(SYDownloadResponseBlock)responseBlock downloadProgressBlock:(SYDownloadProgressBlock)progressBlock completeBlock:(SYDownloadCompletedBlock)completeBlock cancelBlock:(SYDownloaderCancelBlock)cancelBlock{
    self = [super init];
    if (self) {
        _requst = [requst copy];
        _responseBlock = [responseBlock copy];
        _progressBlock = [progressBlock copy];
        _completeBlock = [completeBlock copy];
        _cancelBlock = [cancelBlock copy];
    }
    return self;
}

- (void)start{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    if (self.isCancelled) {
        [self done];
        return;
    }
    
    @synchronized (self) {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.timeoutIntervalForRequest  = 15.0f;
        _session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:NSOperationQueue.mainQueue];
        _task = [_session dataTaskWithRequest:_requst];
        [_task resume];
    }
}

-(void)cancel{
    @synchronized (self) {
        [self done];
    }
}

-(void)done{
    [super cancel];
    if (_executing) {
        [self willChangeValueForKey:@"isFinished"];
        [self willChangeValueForKey:@"isExecuting"];
        _finished = YES;
        _executing = NO;
        [self didChangeValueForKey:@"isFinished"];
        [self didChangeValueForKey:@"isExecuting"];
        [self reset];  ///MARK:重置
    }
}

-(void)reset{
    if (self.task) {
        [_task cancel];
    }
    
    if (self.session) {
        [self.session invalidateAndCancel];
        self.session = nil;
    }
}

#pragma mark <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>
///MARK:响应回调
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    if (_responseBlock) {
        _responseBlock(httpResponse);
    }
    
    if ([httpResponse statusCode] == 200) {
        completionHandler(NSURLSessionResponseAllow);
        self.data = [[NSMutableData alloc]init];
        self.expectedSize= response.expectedContentLength>0?(NSInteger)response.expectedContentLength:0;
    }else{
        completionHandler(NSURLSessionResponseCancel);
    }
}

////MARK: 下载进度回调
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{
    [self.data appendData:data];
    if (self.progressBlock) {
        self.progressBlock(self.data.length, self.expectedSize, data);
    }
}

///MARK: 下载完成回调
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error{
    if (self.completeBlock) {
        if (error) {
            if (error.code == NSURLErrorCancelled) {
                self.cancelBlock();
            }else{
                self.completeBlock(nil, error, NO);
            }
        }else{
            self.completeBlock(self.data,nil, YES);
        }
    }
    [self done];
}

///MARK:存数据缓存
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * _Nullable))completionHandler {
    NSCachedURLResponse *cachedResponse = proposedResponse;
    if (self.requst.cachePolicy == NSURLRequestReloadIgnoringCacheData) {
        cachedResponse = nil;
    }
    if (completionHandler) {
        completionHandler(cachedResponse);
    }
}


#pragma mark private
-(BOOL)isExecuting{
    return _executing;
}

-(BOOL)isFinished{
    return _finished;
}

-(BOOL)isAsynchronous{
    return YES;
}

@end
