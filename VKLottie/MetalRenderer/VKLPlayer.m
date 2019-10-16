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
    }
    return self;
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {

}

- (void)drawInMTKView:(MTKView *)view {

    const VKLVertex vertices[] = {
        { { -1, -1 } },
        { { +1, -1 } },
        { { -1, +1 } },
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
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:3];
        [renderEncoder endEncoding];
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    [commandBuffer commit];
}

@end
