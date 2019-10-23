//
//  VKLArchiver.m
//  VKLottie
//
//  Created by Антон Сергеев on 16.10.2019.
//

#import "VKLArchiver.h"
#import "VKLRenderer.h"
#import <MetalKit/MetalKit.h>
#import "VKLFileManager.h"
#import "VKLShaderTypes.h"
#include "compression.h"
#include <arm_neon.h>

NS_ASSUME_NONNULL_BEGIN

@interface VKLArchiver ()

@property (nonatomic, readonly, assign) size_t width;
@property (nonatomic, readonly, assign) size_t height;
@property (nonatomic, readonly, assign) size_t scale;

@property (nonatomic, readonly, assign) size_t encodedFrameSize;

@property (nonatomic, readonly, strong) NSArray<NSMutableData *> *compressedFrames;


@end

NS_ASSUME_NONNULL_END

@implementation VKLArchiver

- (instancetype)initWithRenderer:(VKLRenderer *)renderer size:(CGSize)size scale:(CGFloat)scale {
    self = [super init];
    if (self) {
        int pixelCount = size.width * size.height * scale * scale;
        int pointCount = size.width * size.height;
        int pixelInARow = size.width * scale;
        int pixelInAColumn = size.height * scale;
        int pointInARow = size.width;
        int pointInAColumn = size.height;

        

        _width = (size_t)size.width;
        _height = (size_t)size.height;
        _scale = (size_t)scale;
        _encodedFrameSize = _width*_height * (2*_scale*_scale + 2);
        size_t frameCount = (size_t)renderer.frameCount;
        _compressedFrames = ({
            NSMutableArray<NSMutableData *> *array = [NSMutableArray arrayWithCapacity:frameCount];
            for (int i = 0; i < frameCount; i++) {
                array[i] = [NSMutableData data];
            }
            [array copy];
        });

        id<MTLDevice> mtlDevice = MTLCreateSystemDefaultDevice();
        NSBundle *bundle = [NSBundle bundleForClass:VKLArchiver.class];
        id<MTLLibrary> defaultLibrary = [mtlDevice newDefaultLibraryWithBundle:bundle error:nil];
        id<MTLFunction> function = [defaultLibrary newFunctionWithName:@"tempName"];
        id<MTLComputePipelineState> pipelineState = [mtlDevice newComputePipelineStateWithFunction:function error:nil];
        MTLSize threadgroupSize = MTLSizeMake(4 * scale, 4 * scale, 1);
        MTLSize threadgroupCount = MTLSizeMake((size.width * scale  + threadgroupSize.width -  1) / threadgroupSize.width,
                                               (size.height * scale  + threadgroupSize.height -  1) / threadgroupSize.height,
                                               1);
        id<MTLCommandQueue> commandQueue = [mtlDevice newCommandQueue];

        id<MTLBuffer> mtlDecodedBuffer = [mtlDevice newBufferWithLength:pixelCount * 4
                                                                options:MTLResourceStorageModeShared];
        id<MTLBuffer> mtlPreviousBuffer = [mtlDevice newBufferWithLength:pixelCount * 4
                                                                 options:MTLResourceStorageModePrivate];
        id<MTLBuffer> mtlEncodedBuffer = [mtlDevice newBufferWithLength:pixelCount * 2 + pointCount * 2
                                                                options:MTLResourceStorageModeShared];

        NSTimeInterval begin = NSProcessInfo.processInfo.systemUptime;

        for (NSInteger i = 0; i < frameCount; i++) {
            uint8_t *buffer = (uint8_t *)mtlDecodedBuffer.contents;

            [renderer renderedBuffer:buffer forFrame:i size:size scale:scale];

            id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

            id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];

            [computeEncoder setComputePipelineState:pipelineState];

            [computeEncoder setBuffer:mtlDecodedBuffer
                               offset:0
                              atIndex:VKLKernelInputIndexDecodedBuffer];

            [computeEncoder setBuffer:mtlPreviousBuffer
                               offset:0
                              atIndex:VKLKernelInputIndexPreviousYBuffer];
            [computeEncoder setBuffer:mtlPreviousBuffer
                               offset:pixelCount
                              atIndex:VKLKernelInputIndexPreviousUBuffer];
            [computeEncoder setBuffer:mtlPreviousBuffer
                               offset:pixelCount * 2
                              atIndex:VKLKernelInputIndexPreviousVBuffer];
            [computeEncoder setBuffer:mtlPreviousBuffer
                               offset:pixelCount * 3
                              atIndex:VKLKernelInputIndexPreviousABuffer];

            [computeEncoder setBuffer:mtlEncodedBuffer
                               offset:0
                              atIndex:VKLKernelInputIndexEncodedYBuffer];
            [computeEncoder setBuffer:mtlEncodedBuffer
                               offset:pixelCount
                              atIndex:VKLKernelInputIndexEncodedUBuffer];
            [computeEncoder setBuffer:mtlEncodedBuffer
                               offset:pixelCount + pointCount
                              atIndex:VKLKernelInputIndexEncodedVBuffer];
            [computeEncoder setBuffer:mtlEncodedBuffer
                               offset:pixelCount + pointCount * 2
                              atIndex:VKLKernelInputIndexEncodedABuffer];

            vector_float2 size = {pointInARow, pointInAColumn};
            [computeEncoder setBytes:&size
                              length:sizeof(size)
                             atIndex:VKLKernelInputIndexSize];
            float fscale = (float)scale;
            [computeEncoder setBytes:&fscale
                              length:sizeof(fscale)
                             atIndex:VKLKernelInputIndexScale];

            [computeEncoder dispatchThreadgroups:threadgroupCount
                           threadsPerThreadgroup:threadgroupSize];

            [computeEncoder endEncoding];

            [commandBuffer commit];

            [commandBuffer waitUntilCompleted];


            NSData *encodedFrame = [NSData dataWithBytes:mtlEncodedBuffer.contents length:_encodedFrameSize];
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
                void *compressedFrame = malloc(self.encodedFrameSize);
                const size_t encodedBufferSize = compression_encode_buffer(compressedFrame, self.encodedFrameSize, encodedFrame.bytes, self.encodedFrameSize, nil, COMPRESSION_LZFSE);
                [self.compressedFrames[i] appendBytes:compressedFrame length:encodedBufferSize];
                free(compressedFrame);
            });


//            fwrite(mtlEncodedBuffer.contents, encodedBufferSize, 1, animationFile);
//            [frameOffsets addObject:@(currentOffset)];
//            [frameLengths addObject:@(encodedBufferSize)];
//            currentOffset += encodedBufferSize;
//            if (maxEncodedBufferLength < encodedBufferSize) {
//                maxEncodedBufferLength = encodedBufferSize;
//            }
        }

        NSTimeInterval end = NSProcessInfo.processInfo.systemUptime;
        NSLog(@"%f", end - begin);

    }
    return self;
}

- (void)encodedBuffer:(void *)buffer forFrame:(NSInteger)frame {
    while (self.compressedFrames[frame].length == 0) {
        NSLog(@"waiting");
    }
    compression_decode_buffer(buffer, self.encodedFrameSize, self.compressedFrames[frame].mutableBytes, self.compressedFrames[frame].length, nil, COMPRESSION_LZFSE);
}

@end
