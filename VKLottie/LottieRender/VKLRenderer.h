//
//  VKLRenderer.h
//  VKLottie
//
//  Created by Антон Сергеев on 15.10.2019.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>

NS_ASSUME_NONNULL_BEGIN

@interface VKLRenderer : NSObject

@property (nonatomic, readonly, assign) NSInteger frameRate;
@property (nonatomic, readonly, assign) NSInteger frameCount;
@property (nonatomic, readonly, assign) CGSize size;
@property (nonatomic, readonly, assign) CFTimeInterval duration;

@property (nonatomic, readonly, copy) NSString *cacheKey;

- (instancetype)initWithAnimationData:(NSData *)animationData cahceKey:(NSString *)cacheKey;
- (void)renderedBuffer:(void *)buffer forFrame:(NSInteger)frame size:(CGSize)size scale:(CGFloat)scale;

@end

NS_ASSUME_NONNULL_END
