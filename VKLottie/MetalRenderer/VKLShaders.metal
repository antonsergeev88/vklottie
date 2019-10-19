//
//  VKLShaders.metal
//  VKLottie
//
//  Created by Антон Сергеев on 16.10.2019.
//

#include <metal_stdlib>
#include "VKLShaderTypes.h"
using namespace metal;

typedef struct
{
    float4 position [[position]];
} RasterizerData;

vertex RasterizerData vertexShader(uint vertexID [[vertex_id]],
                                   constant VKLVertex *vertices [[buffer(VKLVertexInputIndexVertices)]])
{
    RasterizerData out;
    out.position = float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = vertices[vertexID].position.xy;
    return out;
}

float3 yuv2bgr(float y, float u, float v) {
    float c = y - 0;
    float d = u - 128;
    float e = v - 128;

    float r = c + 1.402*e;
    float g = c - 0.344*d - 0.714*e;
    float b = c + 1.772*d;
    return float3(b / 255.0, g / 255.0, r / 255.0);
}

float raw2alpha(uint8_t raw) {
    return raw / 255.0;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]],

                               constant uint8_t *yEn [[buffer(VKLFragmentInputIndexEncodedYBuffer)]],
                               constant uint8_t *uEn [[buffer(VKLFragmentInputIndexEncodedUBuffer)]],
                               constant uint8_t *vEn [[buffer(VKLFragmentInputIndexEncodedVBuffer)]],
                               constant uint8_t *aEn [[buffer(VKLFragmentInputIndexEncodedABuffer)]],

                               device uint8_t *yDe [[buffer(VKLFragmentInputIndexDecodedYBuffer)]],
                               device uint8_t *uDe [[buffer(VKLFragmentInputIndexDecodedUBuffer)]],
                               device uint8_t *vDe [[buffer(VKLFragmentInputIndexDecodedVBuffer)]],
                               device uint8_t *aDe [[buffer(VKLFragmentInputIndexDecodedABuffer)]],

                               constant float2 *size [[buffer(VKLFragmentInputIndexSize)]],
                               constant float *fscale [[buffer(VKLFragmentInputIndexScale)]],
                               constant int *frame [[buffer(VKLFragmentInputIndexFrame)]])
{
    int scale = (int)(*fscale);
    float2 pos = in.position.xy;
    int posX = (int)pos.x; int pointX = posX / scale;
    int posY = (int)pos.y; int pointY = posY / scale;
    int sizeX = (int)(*size).x; int pointSizeX = sizeX / scale;

    int pixelOffset = posY * sizeX + posX;
    int pointOffset = pointY * pointSizeX + pointX;

    if (*frame == 0) {
        yDe[pixelOffset] = 0;
        uDe[pixelOffset] = 0;
        vDe[pixelOffset] = 0;
        aDe[pixelOffset] = 0;
    }

    uint8_t y = yEn[pixelOffset] ^ yDe[pixelOffset];
    yDe[pixelOffset] = y;
    uint8_t u = uEn[pointOffset] ^ uDe[pixelOffset];
    uDe[pixelOffset] = u;
    uint8_t v = vEn[pointOffset] ^ vDe[pixelOffset];
    vDe[pixelOffset] = v;
    uint8_t a = aEn[pixelOffset] ^ aDe[pixelOffset];
    aDe[pixelOffset] = a;
    float alpha = raw2alpha(a);
    float3 bgr = yuv2bgr(y, u, v);
    return float4(bgr, alpha);
}

kernel void tempName(uint2 pos [[thread_position_in_grid]],
                     constant uint8_t *de [[buffer(VKLKernelInputIndexDecodedBuffer)]],

                     device uint8_t *yPr [[buffer(VKLKernelInputIndexPreviousYBuffer)]],
                     device uint8_t *uPr [[buffer(VKLKernelInputIndexPreviousUBuffer)]],
                     device uint8_t *vPr [[buffer(VKLKernelInputIndexPreviousVBuffer)]],
                     device uint8_t *aPr [[buffer(VKLKernelInputIndexPreviousABuffer)]],

                     device uint8_t *yEn [[buffer(VKLKernelInputIndexEncodedYBuffer)]],
                     device uint8_t *uEn [[buffer(VKLKernelInputIndexEncodedUBuffer)]],
                     device uint8_t *vEn [[buffer(VKLKernelInputIndexEncodedVBuffer)]],
                     device uint8_t *aEn [[buffer(VKLKernelInputIndexEncodedABuffer)]],

                     constant float2 *fsize [[buffer(VKLKernelInputIndexSize)]],
                     constant float *fscale [[buffer(VKLKernelInputIndexScale)]]) {
    const int scale = (int)(*fscale);
    const int posX = pos.x; const int pointX = posX / scale;
    const int posY = pos.y; const int pointY = posY / scale;
    const float2 size = *fsize;
    const int sizeX = ((int)size.x) * scale; const int pointSizeX = (int)size.x;
    const int sizeY = ((int)size.y) * scale; const int pointSizeY = (int)size.y;

    const int pixelOffset = posY * sizeX + posX;
    const int pointOffset = pointY * pointSizeX + pointX;

    if (posX > sizeX || posY > sizeY) {
        return;
    }

    const uint8_t r = de[pixelOffset * 4 + 0];
    const uint8_t g = de[pixelOffset * 4 + 1];
    const uint8_t b = de[pixelOffset * 4 + 2];
    const uint8_t a = de[pixelOffset * 4 + 3];

    const int yRaw = 0.299*r + 0.587*g + 0.114*b;
    const uint8_t y = (uint8_t)clamp(yRaw, 0, 255);
    yEn[pixelOffset] = y ^ yPr[pixelOffset];
    yPr[pixelOffset] = y;

    if (posX % scale == 0 && posY % scale == 0) {
        const int uRaw = -0.169*r - 0.331*g + 0.499*b + 128;
        const uint8_t u = (uint8_t)clamp(uRaw, 0, 255);
        uEn[pointOffset] = u ^ uPr[pixelOffset];
        uPr[pixelOffset] = u;

        const int vRaw = 0.499*r - 0.418*g - 0.0813*b + 128;
        const uint8_t v = (uint8_t)clamp(vRaw, 0, 255);
        vEn[pointOffset] = v ^ vPr[pixelOffset];
        vPr[pixelOffset] = v;
    }

    aEn[pixelOffset] = a ^ aPr[pixelOffset];
    aPr[pixelOffset] = a;

}
