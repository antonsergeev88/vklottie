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
        _animationView = [[MTKView alloc] init];
    }
    return self;
}

#pragma mark - Player

- (void)setPlayer:(VKLPlayer *)player {
    _player = player;
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
