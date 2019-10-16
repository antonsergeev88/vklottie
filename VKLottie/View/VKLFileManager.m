//
//  VKLFileManager.m
//  VKLottie
//
//  Created by Антон Сергеев on 16.10.2019.
//

#import "VKLFileManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface VKLFileManager ()

@property (nonatomic, readonly, strong) NSFileManager *fileManager;
@property (nonatomic, readonly, copy) NSString *rootPath;

@end

NS_ASSUME_NONNULL_END

@implementation VKLFileManager

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *temporaryDirectory = NSTemporaryDirectory();
        NSString *vklDirectory = [temporaryDirectory stringByAppendingPathComponent:@"vkl"];
        NSFileManager *fileManager = NSFileManager.defaultManager;
        _fileManager = fileManager;
        [fileManager createDirectoryAtPath:vklDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        _rootPath = vklDirectory;
    }
    return self;
}

+ (instancetype)shared {
    __block VKLFileManager *fileManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fileManager = [[VKLFileManager alloc] init];
    });
    return fileManager;
}

- (NSString *)pathForCacheKey:(NSString *)cacheKey size:(CGSize)size scale:(CGFloat)scale {
    NSData *data = [cacheKey dataUsingEncoding:NSUTF8StringEncoding];
    NSString *safeCacheKey = [data base64EncodedStringWithOptions:0];
    NSString *completeCacheKey = [NSString stringWithFormat:@"%@_(%d,%d)x%d", safeCacheKey, (int)size.width, (int)size.height, (int)scale];
    NSString *path = [self.rootPath stringByAppendingPathComponent:completeCacheKey];
    [self.fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    return path;
}

@end
