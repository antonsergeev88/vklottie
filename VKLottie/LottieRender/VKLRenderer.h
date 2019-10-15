//
//  VKLRenderer.h
//  VKLottie
//
//  Created by Антон Сергеев on 15.10.2019.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VKLRenderer : NSObject

- (instancetype)initWithAnimationData:(NSData *)animationData cahceKey:(NSString *)cacheKey;

@end

NS_ASSUME_NONNULL_END
