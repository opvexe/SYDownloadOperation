//
//  SYCacheManger.m
//  SYDownloadOperation
//
//  Created by FaceBook on 2019/2/1.
//  Copyright © 2019年 FaceBook. All rights reserved.
//

#import "SYCacheManger.h"
#import <CommonCrypto/CommonDigest.h>
@interface SYCacheManger()
@property(nonatomic,strong)NSCache *cache;
@property(nonatomic,strong)NSFileManager *fileManager;
@property(nonatomic,strong)NSURL *diskCacheDirectoryURL;
@property(nonatomic,strong)dispatch_queue_t ioQueue;
@end
@implementation SYCacheManger

+ (SYCacheManger *)sharedWebCache{
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
        _cache = [[NSCache alloc]init];
        _cache.name = @"WebCache";
        _cache.totalCostLimit = 50*1024*1025;
        
        _fileManager = [NSFileManager defaultManager];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path = paths.lastObject;
        
        NSString *diskCachePath = [NSString stringWithFormat:@"%@%@",path,@"/WebCache"];
        BOOL isDirectory = NO;
        BOOL isExisted = [_fileManager fileExistsAtPath:diskCachePath];
        if (!isExisted||!isDirectory) {
            NSError *error;
            [_fileManager createDirectoryAtPath:diskCachePath withIntermediateDirectories:YES attributes:nil error:&error];
        }
        
        _diskCacheDirectoryURL =[NSURL fileURLWithPath:path];
        _ioQueue = dispatch_queue_create("com.dispathch.cache", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}


-(NSOperation *)queryDataFromMemory:(NSString *)key cacheQueryCompletedBlock:(SYCacheQueryCompletedBlock)cacheQueryCompletedBlock{
    return [self queryDataFromMemory:key cacheQueryCompletedBlock:cacheQueryCompletedBlock extension:nil];
}

-(NSOperation *)queryDataFromMemory:(NSString *)key cacheQueryCompletedBlock:(SYCacheQueryCompletedBlock)cacheQueryCompletedBlock extension:(NSString *)extension {
    NSOperation *operation = [[NSOperation alloc]init];
    dispatch_sync(_ioQueue, ^{
        if (operation.isCancelled) {
            return ;
        }
        ///MARK: 内存中查找数据
        NSData *data = [self dataFromMemoryCache:key];
        
        ///MARK: 内存没数据，磁盘查找数据
        if (!data) {
            data = [self dataFromDiskCache:key extension:extension];
            [self storeDataToMemoryCache:data key:key];
        }
        
        if (data) {
            cacheQueryCompletedBlock(data,YES);
        }else{
            cacheQueryCompletedBlock(nil,NO);
        }
    });
    return operation;
}

-(NSOperation *)queryURLFromDiskMemory:(NSString *)key cacheQueryCompletedBlock:(SYCacheQueryCompletedBlock)cacheQueryCompletedBlock{
    return  [self queryURLFromDiskMemory:key cacheQueryCompletedBlock:cacheQueryCompletedBlock extension:nil];
}

-(NSOperation *)queryURLFromDiskMemory:(NSString *)key cacheQueryCompletedBlock:(SYCacheQueryCompletedBlock)cacheQueryCompletedBlock extension:(NSString *)extension {
    NSOperation *operation = [NSOperation new];
    dispatch_async(_ioQueue, ^{
        if(operation.isCancelled) {
            return;
        }
        NSString *path = [self diskCachePathForKey:key extension:extension];
        if([self.fileManager fileExistsAtPath:path]) {
            cacheQueryCompletedBlock(path, YES);
        }else {
            cacheQueryCompletedBlock(path, NO);
        }
    });
    return operation;
}

///MARK:从内存查找数据
-(NSData *)dataFromMemoryCache:(NSString *)key {
    return [self.cache objectForKey:key];
}

///MARK: 本地磁盘查找数据
-(NSData *)dataFromDiskCache:(NSString *)key extension:(NSString *)extension {
    return [NSData dataWithContentsOfFile:[self diskCachePathForKey:key extension:extension]];
}

///MARK: 将数据存在内存中
- (void)storeDataToMemoryCache:(NSData *)data key:(NSString *)key {
    if(data && key) {
        [self.cache setObject:data forKey:key];
    }
}

///MARK:将数据存储在磁盘
- (void)storeDataToDiskCache:(NSData *)data key:(NSString *)key {
    [self storeDataToDiskCache:data key:key extension:nil];
}

///MARK:将数据存储在内存和磁盘
-(void)storeDataCache:(NSData *)data forKey:(NSString *)key {
    dispatch_async(_ioQueue, ^{
        [self storeDataToMemoryCache:data key:key];
        [self storeDataToDiskCache:data key:key];
    });
}

///MARK: 将数据存储在磁盘
- (void)storeDataToDiskCache:(NSData *)data key:(NSString *)key extension:(NSString *)extension {
    if(data && key) {
        [_fileManager createFileAtPath:[self diskCachePathForKey:key extension:extension] contents:data attributes:nil];
    }
}

///MAKR:根据key获取文件路径
- (NSString *)diskCachePathForKey:(NSString *)key {
    return [self diskCachePathForKey:key extension:nil];
}


///MARK:清理磁盘内存数据
- (void)clearCache:(SYCacheClearCompletedBlock)cacheClearCompletedBlock {
    dispatch_async(_ioQueue, ^{
        [self clearMemoryCache];
        NSString *cacheSize = [self clearDiskCache];
        if(cacheClearCompletedBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                cacheClearCompletedBlock(cacheSize);
            });
        }
    });
}

///MARK:清理内存数据
-(void)clearMemoryCache{
    [self.cache removeAllObjects];
}

///MARK:清理磁盘内存数据
- (NSString *)clearDiskCache {
    NSArray *contents = [_fileManager contentsOfDirectoryAtPath:_diskCacheDirectoryURL.path error:nil];
    NSEnumerator *enumerator = [contents objectEnumerator];
    NSString *fileName;
    CGFloat folderSize = 0.0f;
    
    while((fileName = [enumerator nextObject])) {
        NSString *filePath = [_diskCacheDirectoryURL.path stringByAppendingPathComponent:fileName];
        folderSize += [_fileManager attributesOfItemAtPath:filePath error:nil].fileSize;
        [_fileManager removeItemAtPath:filePath error:NULL];
    }
    return [NSString stringWithFormat:@"%.2f",folderSize/1024.0f/1024.0f];
}

- (NSString *)diskCachePathForKey:(NSString *)key extension:(NSString *)extension {
    NSString *fileName = [self md5:key];
    NSString *cachePathForKey = [_diskCacheDirectoryURL URLByAppendingPathComponent:fileName].path;
    if(extension) {
        cachePathForKey = [cachePathForKey stringByAppendingFormat:@".%@", extension];
    }
    return cachePathForKey;
}

- (NSString *)md5:(NSString *)key {
    if(!key) {
        return @"temp";
    }
    const char *str = [key UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    return output;
}

@end
