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

@end
