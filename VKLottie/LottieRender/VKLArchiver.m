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
        NSInteger maxEncodedBufferLength = 0;

        NSInteger currentOffset = 0;
        NSInteger frameCount = renderer.frameCount;

        NSInteger pixelCount = size.width * size.height * scale * scale;
        NSInteger pointCount = size.width * size.height;
        NSInteger pixelInARow = size.width * scale;
        NSInteger pointInARow = size.width;

        NSInteger bufferSize = pixelCount * sizeof(uint32_t);
        uint8_t *buffer = malloc(bufferSize);

        NSInteger alphaBufferSize = pixelCount * sizeof(uint8_t) / 2 + ((pixelCount % 2) == 0 ? 0 : 1);
        uint8_t *alphaBuffer = malloc(alphaBufferSize);

        NSInteger yBufferSize = pixelCount * sizeof(uint8_t);
        uint8_t *yBuffer = malloc(yBufferSize);

        NSInteger uBufferSize = pointCount * sizeof(uint8_t);
        uint8_t *uBuffer = malloc(uBufferSize);

        NSInteger vBufferSize = uBufferSize;
        uint8_t *vBuffer = malloc(vBufferSize);

        for (NSInteger i = 0; i < frameCount; i++) {
            [renderer renderedBuffer:buffer forFrame:i size:size scale:scale];

            NSInteger pointIndex = 0;
            for (NSInteger i = 0; i < pixelCount; i++) {

                uint8_t r, g, b, a;
                r = buffer[i * 4 + 0];
                g = buffer[i * 4 + 1];
                b = buffer[i * 4 + 2];
                a = buffer[i * 4 + 3];

                uint8_t rn, gn, bn, an;
                if (i + 1 < pixelCount) {
                    rn = buffer[(i + 1) * 4 + 0];
                    gn = buffer[(i + 1) * 4 + 1];
                    bn = buffer[(i + 1) * 4 + 2];
                    an = buffer[(i + 1) * 4 + 3];
                } else {
                    rn = 0; gn = 0; bn = 0; an = 0;
                }


                // alpha
                if (i % 2 == 0) {
                    uint8_t lAlpha = a; lAlpha >>= 4; lAlpha <<= 4;
                    uint8_t rAlpha = an; rAlpha >>= 4;

                    uint8_t alpha = lAlpha | rAlpha;
                    alphaBuffer[i / 2] = alpha;
                }

                // y
                uint8_t y = ((66ull * (uint64_t)r + 129ull * (uint64_t)g + 25ull * (uint64_t)b + 128ull) >> 8ull) + 16ull;
                yBuffer[i] = y;

                // u
                if ((i / pixelInARow) % (int)scale == 0 && (i % pixelInARow) % (int)scale == 0) {
                    uint8_t u = ((-38ll * (uint64_t)r - 74ll * (uint64_t)g + 112ll * (uint64_t)b + 128ull) >> 8ull) + 128ull;
                    uBuffer[pointIndex] = u;

                    // v
                    uint8_t v = ((112ll * (uint64_t)r - 94ll * (uint64_t)g - 18ll * (uint64_t)b + 128ull) >> 8ull) + 128ull;
                    vBuffer[pointIndex] = v;

                    pointIndex += 1;
                }
            }

            NSInteger encodedBufferSize = 0;
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
