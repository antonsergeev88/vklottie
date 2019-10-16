//
//  VKLPlayer.m
//  VKLottie
//
//  Created by Антон Сергеев on 15.10.2019.
//

#import "VKLPlayer.h"
#import "VKLPlayer+MTKViewDelegate.h"
#import "VKLRenderer.h"
#import "VKLArchiver.h"

NS_ASSUME_NONNULL_BEGIN

@interface VKLPlayer ()

@property (nonatomic, readwrite, assign) CGSize size;
@property (nonatomic, readwrite, assign) CGFloat scale;

@property (nonatomic, readonly, strong) VKLRenderer *renderer;
@property (nonatomic, readonly, strong) VKLArchiver *archiver;

@end

NS_ASSUME_NONNULL_END

@implementation VKLPlayer

- (instancetype)initWithAnimationData:(NSData *)animationData cacheKey:(NSString *)cacheKey size:(CGSize)size scale:(CGFloat)scale {
    self = [super init];
    if (self) {
        _size = size;
        _scale = scale;
        _renderer = [[VKLRenderer alloc] initWithAnimationData:animationData cahceKey:cacheKey];
        _archiver = [[VKLArchiver alloc] initWithRenderer:_renderer size:size scale:scale];
    }
    return self;
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {

}

- (void)drawInMTKView:(MTKView *)view {

}

@end
