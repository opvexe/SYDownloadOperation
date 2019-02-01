//
//  SYCombineOperation.m
//  SYDownloadOperation
//
//  Created by FaceBook on 2019/2/1.
//  Copyright © 2019年 FaceBook. All rights reserved.
//

#import "SYCombineOperation.h"

@implementation SYCombineOperation

- (void)cancel {
    
    if (self.cacheOperation) {
        [self.cacheOperation cancel];
        self.cacheOperation = nil;
    }
    
    if (self.downloadOperation) {
        [self.downloadOperation cancel];
        self.downloadOperation = nil;
    }
    
    if (self.cancelBlock) {
        self.cancelBlock();
        _cancelBlock = nil;
    }
}

@end
