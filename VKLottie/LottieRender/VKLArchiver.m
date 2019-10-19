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

        NSInteger aBufferSize = pixelCount * sizeof(uint8_t);
        uint8_t *aBuffer = malloc(aBufferSize);
        uint8_t *aPreBuffer = malloc(aBufferSize);

        NSInteger yBufferSize = pixelCount * sizeof(uint8_t);
        uint8_t *yBuffer = malloc(yBufferSize);
        uint8_t *yPreBuffer = malloc(yBufferSize);

        NSInteger uBufferSize = pointCount * sizeof(uint8_t);
        uint8_t *uBuffer = malloc(uBufferSize);
        uint8_t *uPreBuffer = malloc(uBufferSize);

        NSInteger vBufferSize = pointCount * sizeof(uint8_t);
        uint8_t *vBuffer = malloc(vBufferSize);
        uint8_t *vPreBuffer = malloc(vBufferSize);

        for (NSInteger i = 0; i < frameCount; i++) {
            [renderer renderedBuffer:buffer forFrame:i size:size scale:scale];

            for (NSInteger j = 0; j < pixelCount; j++) {

                const uint8_t r = buffer[j * 4 + 0];
                const uint8_t g = buffer[j * 4 + 1];
                const uint8_t b = buffer[j * 4 + 2];
                const uint8_t a = buffer[j * 4 + 3];

                // alpha
                aBuffer[j] = a ^ aPreBuffer[j];
                aPreBuffer[j] = a;

                // y
                int y = 0.299*r + 0.587*g + 0.114*b;
                y = MIN(MAX(y, 0), 255);
                yBuffer[j] = y ^ yPreBuffer[j];
                yPreBuffer[j] = y;

            }

            for (int j = 0; j < pointCount; j++) {

                uint8_t r, g, b, a;
                int row = j / pointInARow * (int)scale;
                int column = (j % pointInARow) * (int)scale;
                int k = row * pixelInARow + column;
                r = buffer[k * 4 + 0];
                g = buffer[k * 4 + 1];
                b = buffer[k * 4 + 2];
                a = buffer[k * 4 + 3];

                // u
                int u = -0.169*r - 0.331*g + 0.499*b + 128;
                u = MIN(MAX(u, 0.0), 255.0);
                uBuffer[j] = u ^ uPreBuffer[j];
                uPreBuffer[j] = u;

                // v
                int v = 0.499*r - 0.418*g - 0.0813*b + 128;
                v = MIN(MAX(v, 0.0), 255.0);
                vBuffer[j] = v ^ vPreBuffer[j];
                vPreBuffer[j] = v;

            }

            int encodedBufferSize = 0;
            fwrite(yBuffer, yBufferSize, 1, animationFile);
            encodedBufferSize += yBufferSize;
            fwrite(uBuffer, uBufferSize, 1, animationFile);
            encodedBufferSize += uBufferSize;
            fwrite(vBuffer, vBufferSize, 1, animationFile);
            encodedBufferSize += vBufferSize;
            fwrite(aBuffer, aBufferSize, 1, animationFile);
            encodedBufferSize += aBufferSize;
            [frameOffsets addObject:@(currentOffset)];
            [frameLengths addObject:@(encodedBufferSize)];
            currentOffset += encodedBufferSize;
            if (maxEncodedBufferLength < encodedBufferSize) {
                maxEncodedBufferLength = encodedBufferSize;
            }
        }
        free(vBuffer);
        free(vPreBuffer);
        free(uBuffer);
        free(uPreBuffer);
        free(yBuffer);
        free(yPreBuffer);
        free(aBuffer);
        free(aPreBuffer);
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
