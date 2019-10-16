//
//  VKLView.m
//  VKLottie
//
//  Created by Антон Сергеев on 15.10.2019.
//

#import "VKLView.h"
#import <MetalKit/MetalKit.h>
#import "VKLPlayer.h"
#import "VKLPlayer+MTKViewDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface VKLView ()

@property (nonatomic, readonly, strong) MTKView *animationView;

@end

NS_ASSUME_NONNULL_END

@implementation VKLView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialSetupWithFrame:frame];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self initialSetupWithFrame:self.frame];
    }
    return self;
}

- (void)initialSetupWithFrame:(CGRect)frame {
    _animationView = [[MTKView alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, frame.size.height) device:MTLCreateSystemDefaultDevice()];
    _animationView.opaque = NO;
    _animationView.contentMode = UIViewContentModeCenter;
    [self addSubview:_animationView];
}

#pragma mark - Player

- (VKLPlayer *)player {
    return [self.animationView.delegate isKindOfClass:VKLPlayer.class] ? self.animationView.delegate : nil;
}

- (void)setPlayer:(VKLPlayer *)player {
    [player setupView:self.animationView];
    self.animationView.delegate = player;
}

#pragma mark - Playing

- (BOOL)isPlaying {
    return !self.animationView.paused;
}

- (void)setPlaying:(BOOL)playing {
    self.animationView.paused = !playing;
}

#pragma mark - Layout

- (void)layoutSubviews {
    CGSize size = self.bounds.size;
    self.animationView.frame = CGRectMake(0.0, 0.0, size.width, size.height);
}

@end
