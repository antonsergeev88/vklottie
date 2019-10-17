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

float3 yuv2rgb(uint8_t y, uint8_t u, uint8_t v) {
    int c = y - 16;
    int d = u - 128;
    long e = v - 128;

    int r = min(255, max(0, (298 * c + 409 * e + 128) >> 8));
    int g = min(255, max(0, (298 * c - 100 * d - 208 * e + 128) >> 8));
    int b = min(255, max(0, (298 * c + 516 * d + 128) >> 8));
    return float3(r / 255.0, g / 255.0, b / 255.0);
}

float raw2alpha(uint8_t raw, int index) {
    if (index % 2 == 0) {
        uint8_t lRaw = (raw >> 4) << 4;
        uint8_t rRaw = raw >> 4;
        return (lRaw | rRaw) / 255.0;
    } else {
        uint8_t lRaw = raw << 4;
        uint8_t rRaw = (raw << 4) >> 4;
        return (lRaw | rRaw) / 255.0;
    }
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]],
                               constant uint8_t *encodedBuffer [[buffer(VKLFragmentInputIndexEncodedBuffer)]],
                               constant int *encodedBufferLength [[buffer(VKLFragmentInputIndexEncodedBufferLength)]],
                               constant float2 *size [[buffer(VKLFragmentInputIndexSize)]])
{
    float2 pos = in.position.xy;
    int posX = (int)pos.x;
    int posY = (int)pos.y;
    int sizeX = (int)(*size).x;
    int sizeY = (int)(*size).y;

    int yIndex = posY * sizeX + posX;
    int uIndex = (sizeX * sizeY) + ((int)(posX / 3) * (int)(sizeX / 3)) + (int)(posX / 3);
    int vIndex = (sizeX * sizeY) / 9 + uIndex;
    int alphaIndex = (sizeX * sizeY * 11 / 9) + yIndex / 2;
    uint8_t y = encodedBuffer[yIndex];
    uint8_t u = encodedBuffer[uIndex];
    uint8_t v = encodedBuffer[vIndex];
    float alpha = raw2alpha(encodedBuffer[alphaIndex], alphaIndex);
    float3 rgb = yuv2rgb(y, u, v);
    return float4(rgb, alpha);
}
