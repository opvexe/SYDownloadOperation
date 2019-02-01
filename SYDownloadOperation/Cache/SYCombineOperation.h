//
//  SYCombineOperation.h
//  SYDownloadOperation
//
//  Created by FaceBook on 2019/2/1.
//  Copyright © 2019年 FaceBook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SYDownloadOperation.h"
NS_ASSUME_NONNULL_BEGIN

@interface SYCombineOperation : NSObject

@property(strong,nonatomic)NSOperation *cacheOperation;

@property(strong,nonatomic)SYDownloadOperation *downloadOperation;

@property(nonatomic,copy)SYDownloaderCancelBlock cancelBlock;

-(void)cancel;

@end

NS_ASSUME_NONNULL_END
