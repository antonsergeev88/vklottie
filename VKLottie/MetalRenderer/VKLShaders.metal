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

fragment float4 fragmentShader(RasterizerData in [[stage_in]],
                               constant uint8_t *encodedBuffer [[buffer(VKLFragmentInputIndexEncodedBuffer)]],
                               constant int *encodedBufferLength [[buffer(VKLFragmentInputIndexEncodedBufferLength)]],
                               constant float2 *size [[buffer(VKLFragmentInputIndexSize)]])
{
    float2 pos = in.position.xy;
    int yIndex = (int)((int)pos.y * (int)(*size).x + (int)pos.x);
    uint8_t y = encodedBuffer[yIndex];
    uint8_t u = 1;
    uint8_t v = 1;
    float3 rgb = yuv2rgb(y, u, v);
    return float4(rgb, 1);
//    int index = (int)((int)pos.y * (int)(*size).x + (int)pos.x) * 4;
//    return float4(encodedBuffer[index + 2] / 255.0, encodedBuffer[index + 1] / 255.0, encodedBuffer[index + 0] / 255.0, encodedBuffer[index + 3] / 255.0);
}
