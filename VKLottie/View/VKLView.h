//
//  VKLView.h
//  VKLottie
//
//  Created by Антон Сергеев on 15.10.2019.
//

#import <UIKit/UIKit.h>

@class VKLPlayer;

NS_ASSUME_NONNULL_BEGIN

@interface VKLView : UIView

@property (nonatomic, readwrite, strong) VKLPlayer *player;
@property (nonatomic, readwrite, assign, getter=isPlaying) BOOL playing;

@end

NS_ASSUME_NONNULL_END
