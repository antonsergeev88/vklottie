//
//  VKLPlayer.m
//  VKLottie
//
//  Created by Антон Сергеев on 15.10.2019.
//

#import "VKLPlayer.h"
#import "VKLPlayer+MTKViewDelegate.h"
#import "VKLRenderer.h"

static void release(void *info, const void *data, size_t size) {
    free((uint32_t *)data);
}

NS_ASSUME_NONNULL_BEGIN

@interface VKLPlayer ()

@property (nonatomic, readwrite, assign) CGSize size;
@property (nonatomic, readwrite, assign) CGFloat scale;

@property (nonatomic, readonly, strong) VKLRenderer *renderer;
@property (nonatomic, readwrite, assign) NSUInteger currentFrame;

@end

NS_ASSUME_NONNULL_END

@implementation VKLPlayer

- (instancetype)initWithAnimationData:(NSData *)animationData cacheKey:(NSString *)cacheKey size:(CGSize)size scale:(CGFloat)scale {
    self = [super init];
    if (self) {
        _size = size;
        _scale = scale;
        _renderer = [[VKLRenderer alloc] initWithAnimationData:animationData cahceKey:cacheKey];
    }
    return self;
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {

}

- (void)drawInMTKView:(MTKView *)view {
    if (view.preferredFramesPerSecond != self.renderer.frameRate) {
        view.preferredFramesPerSecond = self.renderer.frameRate;
    }
    void *buffer = malloc(sizeof(uint32_t) * self.size.width * self.size.height * self.scale * self.scale);
    [self.renderer renderedBuffer:buffer forFrame:self.currentFrame size:self.size scale:self.scale];
    self.currentFrame = (self.currentFrame + 1) % self.renderer.frameCount;
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, buffer, sizeof(uint32_t) * self.size.width * self.size.height * self.scale * self.scale, release);
    CGImageRef cgImage = CGImageCreate(self.size.width * self.scale, self.size.height * self.scale, 8, 32, self.size.width * self.scale * 4, CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrder32Little|kCGImageAlphaPremultipliedFirst, dataProvider, NULL, false, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    view.superview.layer.contents = CFBridgingRelease(cgImage);
}

@end
