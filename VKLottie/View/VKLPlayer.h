//
//  VKLPlayer.h
//  VKLottie
//
//  Created by Антон Сергеев on 15.10.2019.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface VKLPlayer : NSObject

- (instancetype)initWithAnimationData:(NSData *)animationData size:(CGSize)size scale:(CGFloat)scale;

@end

NS_ASSUME_NONNULL_END
