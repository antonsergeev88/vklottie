//
//  VKLArchiver.m
//  VKLottie
//
//  Created by Антон Сергеев on 16.10.2019.
//

#import "VKLArchiver.h"
#import "VKLRenderer.h"
#import "VKLFileManager.h"

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
        int pointInARow = size.width;

        int bufferSize = pixelCount * sizeof(uint32_t);
        uint8_t *buffer = malloc(bufferSize);

        NSInteger alphaBufferSize = pixelCount * sizeof(uint8_t);
        uint8_t *alphaBuffer = malloc(alphaBufferSize);

        NSInteger yBufferSize = pixelCount * sizeof(uint8_t);
        uint8_t *yBuffer = malloc(yBufferSize);

        NSInteger uBufferSize = pointCount * sizeof(uint8_t);
        uint8_t *uBuffer = malloc(uBufferSize);

        NSInteger vBufferSize = pointCount * sizeof(uint8_t);
        uint8_t *vBuffer = malloc(vBufferSize);

        for (NSInteger i = 0; i < frameCount; i++) {
            [renderer renderedBuffer:buffer forFrame:i size:size scale:scale];

            for (NSInteger i = 0; i < pixelCount; i++) {

                uint8_t r, g, b, a;
                r = buffer[i * 4 + 0];
                g = buffer[i * 4 + 1];
                b = buffer[i * 4 + 2];
                a = buffer[i * 4 + 3];

                // alpha
                alphaBuffer[i] = a;

                // y
                int y = 0.299*r + 0.587*g + 0.114*b;
                yBuffer[i] = MIN(MAX(y, 0), 255);

            }

            for (int i = 0; i < pointCount; i++) {

                uint8_t r, g, b, a;
                int row = i / pointInARow * (int)scale;
                int column = (i % pointInARow) * (int)scale;
                int j = row * pixelInARow + column;
                r = buffer[j * 4 + 0];
                g = buffer[j * 4 + 1];
                b = buffer[j * 4 + 2];
                a = buffer[j * 4 + 3];

                // u
                int u = -0.169*r - 0.331*g + 0.499*b + 128;
                uBuffer[i] = MIN(MAX(u, 0), 255);

                // v
                int v = 0.499*r - 0.418*g - 0.0813*b + 128;
                vBuffer[i] = MIN(MAX(v, 0), 255);

            }

            int encodedBufferSize = 0;
            fwrite(yBuffer, yBufferSize, 1, animationFile);
            encodedBufferSize += yBufferSize;
            fwrite(uBuffer, uBufferSize, 1, animationFile);
            encodedBufferSize += uBufferSize;
            fwrite(vBuffer, vBufferSize, 1, animationFile);
            encodedBufferSize += vBufferSize;
            fwrite(alphaBuffer, alphaBufferSize, 1, animationFile);
            encodedBufferSize += alphaBufferSize;
            [frameOffsets addObject:@(currentOffset)];
            [frameLengths addObject:@(encodedBufferSize)];
            currentOffset += encodedBufferSize;
            if (maxEncodedBufferLength < encodedBufferSize) {
                maxEncodedBufferLength = encodedBufferSize;
            }
        }
        free(vBuffer);
        free(uBuffer);
        free(yBuffer);
        free(alphaBuffer);
        free(buffer);
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
}

@end
