//
//  VKLArchiver.h
//  VKLottie
//
//  Created by Антон Сергеев on 16.10.2019.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>

@class VKLRenderer;

NS_ASSUME_NONNULL_BEGIN

@interface VKLArchiver : NSObject

@property (nonatomic, readonly, assign) NSInteger maxEncodedBufferLength;

- (instancetype)initWithRenderer:(VKLRenderer *)renderer size:(CGSize)size scale:(CGFloat)scale;

- (void)encodedBuffer:(void *)buffer forFrame:(NSInteger)frame;

@end

NS_ASSUME_NONNULL_END
