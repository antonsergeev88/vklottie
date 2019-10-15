//
//  VKLPlayer.m
//  VKLottie
//
//  Created by Антон Сергеев on 15.10.2019.
//

#import "VKLPlayer.h"
#import "VKLPlayer+MTKViewDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface VKLPlayer ()

@property (nonatomic, readwrite, assign) CGSize size;
@property (nonatomic, readwrite, assign) CGFloat scale;

@end

NS_ASSUME_NONNULL_END

@implementation VKLPlayer

- (instancetype)initWithAnimationData:(NSData *)animationData size:(CGSize)size scale:(CGFloat)scale {
    self = [super init];
    if (self) {
        _size = size;
        _scale = scale;
    }
    return self;
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {

}

- (void)drawInMTKView:(MTKView *)view {

}

@end
