//
//  VKLFileManager.h
//  VKLottie
//
//  Created by Антон Сергеев on 16.10.2019.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>

NS_ASSUME_NONNULL_BEGIN

@interface VKLFileManager : NSObject

+ (instancetype)shared;

- (NSString *)pathForCacheKey:(NSString *)cacheKey size:(CGSize)size scale:(CGFloat)scale;

@end

NS_ASSUME_NONNULL_END
