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
    return ((raw << 4) | raw) / 255.0;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]],
                               constant uint8_t *encodedBuffer [[buffer(VKLFragmentInputIndexEncodedBuffer)]],
                               constant int *encodedBufferLength [[buffer(VKLFragmentInputIndexEncodedBufferLength)]],
                               constant float2 *size [[buffer(VKLFragmentInputIndexSize)]])
{
    float2 pos = in.position.xy;
    int sizeX = (int)(*size).x;
    int sizeY = (int)(*size).y;
    int posX = (int)pos.x;
    int posY = (int)pos.y;
    int posXY = posY * sizeX + posX;

    int yIndex = posY * sizeX + posX;
    int uIndex = (sizeX * sizeY) + yIndex;
    int vIndex = (sizeX * sizeY) * 2 + yIndex;
    int aIndex = (sizeX * sizeY * 3) + (yIndex / 2);
    uint8_t y = encodedBuffer[yIndex];
    uint8_t u = encodedBuffer[uIndex];
    uint8_t v = encodedBuffer[vIndex];
    uint8_t a = encodedBuffer[aIndex]; a = posXY % 2 == 0 ? a >> 4 : a & 0x0F;
    return float4(yuv2bgr(y, u, v), raw2alpha(a));
}
