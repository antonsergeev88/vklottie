//
//  VKLShaderTypes.h
//  VKLottie
//
//  Created by Антон Сергеев on 16.10.2019.
//

#ifndef VKLShaderTypes_h
#define VKLShaderTypes_h

typedef enum VKLVertexInputIndex {
    VKLVertexInputIndexVertices,
} VKLVertexInputIndex;

typedef enum VKLFragmentInputIndex {
    VKLFragmentInputIndexEncodedYBuffer,
    VKLFragmentInputIndexEncodedUBuffer,
    VKLFragmentInputIndexEncodedVBuffer,
    VKLFragmentInputIndexEncodedABuffer,
    VKLFragmentInputIndexDecodedYBuffer,
    VKLFragmentInputIndexDecodedUBuffer,
    VKLFragmentInputIndexDecodedVBuffer,
    VKLFragmentInputIndexDecodedABuffer,
    VKLFragmentInputIndexSize,
    VKLFragmentInputIndexScale,
    VKLFragmentInputIndexFrame,
} VKLFragmentInputIndex;

typedef struct {
    vector_float2 position;
} VKLVertex;

#endif /* VKLShaderTypes_h */
