//
//  VKLPlayer.m
//  VKLottie
//
//  Created by Антон Сергеев on 15.10.2019.
//

#import "VKLPlayer.h"
#import "VKLPlayer+MTKViewDelegate.h"
#import "VKLRenderer.h"
#import "VKLArchiver.h"
#import "VKLShaderTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface VKLPlayer ()

@property (nonatomic, readwrite, assign) CGSize size;
@property (nonatomic, readwrite, assign) CGFloat scale;

@property (nonatomic, readonly, strong) VKLRenderer *renderer;
@property (nonatomic, readonly, strong) VKLArchiver *archiver;

@property (nonatomic, readonly, strong) id<MTLDevice> mtlDevice;
@property (nonatomic, readonly, strong) id<MTLRenderPipelineState> mtlPipelineState;
@property (nonatomic, readonly, strong) id<MTLCommandQueue> mtlCommandQueue;
@property (nonatomic, readonly, strong) id<MTLBuffer> mtlEncodedBuffer;
@property (nonatomic, readonly, strong) id<MTLBuffer> mtlDecodedBuffer;

@property (nonatomic, readwrite, assign) NSInteger currentFrame;

@end

NS_ASSUME_NONNULL_END

@implementation VKLPlayer

- (instancetype)initWithAnimationData:(NSData *)animationData cacheKey:(NSString *)cacheKey size:(CGSize)size scale:(CGFloat)scale {
    self = [super init];
    if (self) {
        _size = size;
        _scale = scale;
        _renderer = [[VKLRenderer alloc] initWithAnimationData:animationData cahceKey:cacheKey];
        _archiver = [[VKLArchiver alloc] initWithRenderer:_renderer size:size scale:scale];

        _mtlDevice = MTLCreateSystemDefaultDevice();

        NSBundle *bundle = [NSBundle bundleForClass:VKLPlayer.class];
        id<MTLLibrary> defaultLibrary = [_mtlDevice newDefaultLibraryWithBundle:bundle error:nil];

        id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
        id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];

        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"Simple Pipeline";
        pipelineStateDescriptor.vertexFunction = vertexFunction;
        pipelineStateDescriptor.fragmentFunction = fragmentFunction;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

        _mtlPipelineState = [_mtlDevice newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                                 error:nil];

        _mtlCommandQueue = [_mtlDevice newCommandQueue];

        _mtlEncodedBuffer = [_mtlDevice newBufferWithLength:size.width * size.height * (scale * scale * 2 + 2) options:MTLResourceStorageModeShared];
        _mtlDecodedBuffer = [_mtlDevice newBufferWithLength:size.width * size.height * scale * scale * 4 options:MTLResourceStorageModePrivate];
    }
    return self;
}

- (void)setupView:(MTKView *)mtkView {
    mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    mtkView.drawableSize = CGSizeMake(self.size.width * self.scale, self.size.height * self.scale);
    mtkView.autoResizeDrawable = NO;
    mtkView.bounds = CGRectMake(0.0, 0.0, self.size.width, self.size.height);
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    NSAssert(false, @"You should not change drawable size");
}

- (void)drawInMTKView:(MTKView *)view {
    if (view.preferredFramesPerSecond != self.renderer.frameRate) {
        view.preferredFramesPerSecond = self.renderer.frameRate;
    }

    const VKLVertex vertices[] = {
        { { -1, -1 } },
        { { +1, -1 } },
        { { -1, +1 } },
        { { +1, -1 } },
        { { -1, +1 } },
        { { +1, +1 } },
    };

    id<MTLCommandBuffer> commandBuffer = [self.mtlCommandQueue commandBuffer];
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if(renderPassDescriptor != nil) {
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, view.drawableSize.width, view.drawableSize.height, 0.0, 1.0 }];
        [renderEncoder setRenderPipelineState:self.mtlPipelineState];

        [renderEncoder setVertexBytes:vertices
                               length:sizeof(vertices)
                              atIndex:VKLVertexInputIndexVertices];

        NSInteger encodedBufferLength;

        NSInteger pointCount = self.size.width * self.size.height;
        NSInteger pixelCount = pointCount * self.scale * self.scale;;
        [self.archiver encodedBuffer:self.mtlEncodedBuffer.contents length:&encodedBufferLength forFrame:self.currentFrame];
        [renderEncoder setFragmentBuffer:self.mtlEncodedBuffer
                                  offset:0
                                 atIndex:VKLFragmentInputIndexEncodedYBuffer];
        [renderEncoder setFragmentBuffer:self.mtlEncodedBuffer
                                  offset:pixelCount
                                 atIndex:VKLFragmentInputIndexEncodedUBuffer];
        [renderEncoder setFragmentBuffer:self.mtlEncodedBuffer
                                  offset:pixelCount + pointCount
                                 atIndex:VKLFragmentInputIndexEncodedVBuffer];
        [renderEncoder setFragmentBuffer:self.mtlEncodedBuffer
                                  offset:pixelCount + 2 * pointCount
                                 atIndex:VKLFragmentInputIndexEncodedABuffer];

        [renderEncoder setFragmentBuffer:self.mtlDecodedBuffer
                                  offset:0
                                 atIndex:VKLFragmentInputIndexDecodedYBuffer];
        [renderEncoder setFragmentBuffer:self.mtlDecodedBuffer
                                  offset:pixelCount
                                 atIndex:VKLFragmentInputIndexDecodedUBuffer];
        [renderEncoder setFragmentBuffer:self.mtlDecodedBuffer
                                  offset:pixelCount * 2
                                 atIndex:VKLFragmentInputIndexDecodedVBuffer];
        [renderEncoder setFragmentBuffer:self.mtlDecodedBuffer
                                  offset:pixelCount * 3
                                 atIndex:VKLFragmentInputIndexDecodedABuffer];

        vector_float2 size = {self.size.width * self.scale, self.size.height * self.scale};
        [renderEncoder setFragmentBytes:&size
                                 length:sizeof(size)
                                atIndex:VKLFragmentInputIndexSize];
        float scale = self.scale;
        [renderEncoder setFragmentBytes:&scale
                                 length:sizeof(scale)
                                atIndex:VKLFragmentInputIndexScale];
        NSInteger frame = self.currentFrame;
        [renderEncoder setFragmentBytes:&frame
                                 length:sizeof(frame)
                                atIndex:VKLFragmentInputIndexFrame];

        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:6];

        [renderEncoder endEncoding];

        [commandBuffer presentDrawable:view.currentDrawable];
    }
    [commandBuffer commit];
    self.currentFrame = (self.currentFrame + 1) % self.renderer.frameCount;
}

@end
