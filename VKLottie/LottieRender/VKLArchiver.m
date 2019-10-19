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

NS_ASSUME_NONNULL_BEGIN

@interface VKLArchiver ()

@property (nonatomic, readonly, assign) FILE *file;
@property (nonatomic, readonly, copy) NSString *path;
@property (nonatomic, readonly, copy) NSArray<NSNumber *> *frameOffsets;
@property (nonatomic, readonly, copy) NSArray<NSNumber *> *frameLengths;

@end

NS_ASSUME_NONNULL_END

@implementation VKLArchiver

- (instancetype)initWithRenderer:(VKLRenderer *)renderer size:(CGSize)size scale:(CGFloat)scale {
    self = [super init];
    if (self) {
        VKLFileManager *fileManager = VKLFileManager.shared;
        NSString *filePath = [[fileManager pathForCacheKey:renderer.cacheKey size:size scale:scale] copy];
        _path = [filePath copy];
        const char *animationPath = [[[filePath stringByAppendingPathComponent:@"animation"] stringByAppendingPathExtension:@"vkl"] cStringUsingEncoding:NSUTF8StringEncoding];
        FILE *animationFile = fopen(animationPath, "w+");
        _file = animationFile;
        if (animationFile == NULL) {
            return nil;
        }

        NSMutableArray<NSNumber *> *frameOffsets = [NSMutableArray arrayWithCapacity:renderer.frameCount];
        NSMutableArray<NSNumber *> *frameLengths = [NSMutableArray arrayWithCapacity:renderer.frameCount];
        int maxEncodedBufferLength = 0;

        int currentOffset = 0;
        int frameCount = (int)renderer.frameCount;

        int pixelCount = size.width * size.height * scale * scale;
        int pointCount = size.width * size.height;
        int pixelInARow = size.width * scale;
        int pixelInAColumn = size.height * scale;
        int pointInARow = size.width;
        int pointInAColumn = size.height;

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
                                                                 options:MTLResourceStorageModeShared];
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

            int encodedBufferSize = 0;
            fwrite(mtlEncodedBuffer.contents, pixelCount * 2 + pointCount * 2, 1, animationFile);
            encodedBufferSize += pixelCount * 2 + pointCount * 2;
            [frameOffsets addObject:@(currentOffset)];
            [frameLengths addObject:@(encodedBufferSize)];
            currentOffset += encodedBufferSize;
            if (maxEncodedBufferLength < encodedBufferSize) {
                maxEncodedBufferLength = encodedBufferSize;
            }
        }

        NSTimeInterval end = NSProcessInfo.processInfo.systemUptime;
        NSLog(@"%f", end - begin);

        _frameOffsets = [frameOffsets copy];
        _frameLengths = [frameLengths copy];
        _maxEncodedBufferLength = maxEncodedBufferLength;
    }
    return self;
}

- (void)dealloc {
    if (_file != NULL) {
        fclose(_file);
    }
}

- (void)encodedBuffer:(void *)buffer length:(NSInteger *)length forFrame:(NSInteger)frame {
    NSInteger frameOffset = [self.frameOffsets[frame] integerValue];
    NSInteger frameLength = [self.frameLengths[frame] integerValue];
    *length = frameLength;
    fseeko(self.file, frameOffset, SEEK_SET);
    fread(buffer, frameLength, 1, self.file);

//    for (int i = 0; i < 256; i++) {
//        uint8_t *buf = (uint8_t *)buffer;
//        printf("%d", (int)(buf[i * 4]));
//    }
}

@end
