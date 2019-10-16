//
//  VKLPlayer.h
//  VKLottie
//
//  Created by Антон Сергеев on 15.10.2019.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>

@class MTKView;

NS_ASSUME_NONNULL_BEGIN

@interface VKLPlayer : NSObject

- (instancetype)initWithAnimationData:(NSData *)animationData cacheKey:(NSString *)cacheKey size:(CGSize)size scale:(CGFloat)scale;

- (void)setupView:(MTKView *)mtkView;

@end

NS_ASSUME_NONNULL_END
