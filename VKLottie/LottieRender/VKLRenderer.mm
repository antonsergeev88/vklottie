//
//  VKLRenderer.m
//  VKLottie
//
//  Created by Антон Сергеев on 15.10.2019.
//

#import "VKLRenderer.h"
#import "rlottie.h"

using namespace std;
using namespace rlottie;

@implementation VKLRenderer {
    unique_ptr<Animation> _animation;
}

- (instancetype)initWithAnimationData:(NSData *)animationData cahceKey:(NSString *)cacheKey {
    self = [super init];
    if (self) {
        string jsonData = ({
            NSString *nsString = [[NSString alloc] initWithData:animationData encoding:NSUTF8StringEncoding];
            const char *cString = [nsString cStringUsingEncoding:NSUTF8StringEncoding];
            string {cString};
        });
        string key = ({
            const char *cString = [cacheKey cStringUsingEncoding:NSUTF8StringEncoding];
            string {cString};
        });
        _animation = Animation::loadFromData(jsonData, key);
    }
    return self;
}

- (void)renderedBuffer:(void *)buffer forFrame:(NSInteger)frame size:(CGSize)size scale:(CGFloat)scale {
    uint32_t *alignedBuffer = (uint32_t *)buffer;
    CGSize pixelSize = CGSizeMake(size.width * scale, size.height * scale);
    Surface surface(alignedBuffer, (size_t)pixelSize.width, (size_t)pixelSize.height, (size_t)pixelSize.width * sizeof(uint32_t));
    _animation->renderSync((size_t)frame, surface);
}

- (NSInteger)frameRate {
    return (NSInteger)_animation->frameRate();
}

- (NSInteger)frameCount {
    return (NSInteger)_animation->totalFrame();
}

- (CGSize)size {
    size_t width;
    size_t height;
    _animation->size(width, height);
    return CGSizeMake(width, height);
}

- (CFTimeInterval)duration {
    return (CFTimeInterval)_animation->duration();
}

@end
