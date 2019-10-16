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

    return float3(y / 255.0, y / 255.0, y / 255.0);
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
    int yIndex = (int)((int)pos.y * (int)(*size).x + (int)pos.x);
    int alphaIndex = (int)((int)(*size).x * (int)(*size).y) + yIndex / 2;
    uint8_t y = encodedBuffer[yIndex];
    uint8_t u = 1;
    uint8_t v = 1;
    float alpha = raw2alpha(encodedBuffer[alphaIndex], alphaIndex);
    float3 rgb = yuv2rgb(y, u, v);
    return float4(rgb, alpha);
}
