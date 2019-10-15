//
//  VKLView.m
//  VKLottie
//
//  Created by Антон Сергеев on 15.10.2019.
//

#import "VKLView.h"
#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VKLView ()

@property (nonatomic, readonly, strong) MTKView *animationView;

@end

NS_ASSUME_NONNULL_END

@implementation VKLView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _animationView = [[MTKView alloc] init];
    }
    return self;
}

- (void)layoutSubviews {
    CGSize size = self.bounds.size;
    self.animationView.frame = CGRectMake(0.0, 0.0, size.width, size.height);
}

@end
