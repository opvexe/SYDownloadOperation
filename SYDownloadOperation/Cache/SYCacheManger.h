//
//  SYCacheManger.h
//  SYDownloadOperation
//
//  Created by FaceBook on 2019/2/1.
//  Copyright © 2019年 FaceBook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
typedef void(^SYCacheClearCompletedBlock)(NSString *cacheSize);
typedef void(^SYCacheQueryCompletedBlock)(id data, BOOL hasCache);

NS_ASSUME_NONNULL_BEGIN

/*
 * 缓存管理类
 */
@interface SYCacheManger : NSObject

+ (SYCacheManger *)sharedWebCache;

///MARK:根据key去内存和磁盘中查询数据
-(NSOperation *)queryDataFromMemory:(NSString *)key cacheQueryCompletedBlock:(SYCacheQueryCompletedBlock)cacheQueryCompletedBlock;
///MARK:根据key去磁盘中查询数据
-(NSOperation *)queryURLFromDiskMemory:(NSString *)key cacheQueryCompletedBlock:(SYCacheQueryCompletedBlock)cacheQueryCompletedBlock;

- (void)storeDataCache:(NSData *)data forKey:(NSString *)key;
- (void)storeDataToDiskCache:(NSData *)data key:(NSString *)key;
- (void)storeDataToDiskCache:(NSData *)data key:(NSString *)key extension:(NSString *)extension;
- (void)clearCache:(SYCacheClearCompletedBlock) cacheClearCompletedBlock;
@end

NS_ASSUME_NONNULL_END
