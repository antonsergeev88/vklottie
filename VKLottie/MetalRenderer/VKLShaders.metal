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

float raw2alpha(uint8_t raw, int index) {
    return raw / 255.0;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]],
                               constant uint8_t *encodedBuffer [[buffer(VKLFragmentInputIndexEncodedBuffer)]],
                               constant int *encodedBufferLength [[buffer(VKLFragmentInputIndexEncodedBufferLength)]],
                               constant float2 *size [[buffer(VKLFragmentInputIndexSize)]],
                               constant float *fscale [[buffer(VKLFragmentInputIndexScale)]])
{
    int scale = (int)(*fscale);
    float2 pos = in.position.xy;
    int posX = (int)pos.x; int pointX = posX / scale;
    int posY = (int)pos.y; int pointY = posY / scale;
    int sizeX = (int)(*size).x; int pointSizeX = sizeX / scale;
    int sizeY = (int)(*size).y; int pointSizeY = sizeY / scale;

    int pixelOffset = posY * sizeX + posX;
    int pointOffset = pointY * pointSizeX + pointX;

    int yIndex = pixelOffset;
    int uIndex = (sizeX * sizeY) + pointOffset;
    int vIndex = (sizeX * sizeY) * (scale * scale + 1) / (scale * scale) + pointOffset;
    int alphaIndex = (sizeX * sizeY) * (scale * scale + 2) / (scale * scale) + pixelOffset;
    uint8_t y = encodedBuffer[yIndex];
    uint8_t u = encodedBuffer[uIndex];
    uint8_t v = encodedBuffer[vIndex];
    float alpha = raw2alpha(encodedBuffer[alphaIndex], alphaIndex);
    float3 bgr = yuv2bgr(y, u, v);
    return float4(bgr, alpha);
}
