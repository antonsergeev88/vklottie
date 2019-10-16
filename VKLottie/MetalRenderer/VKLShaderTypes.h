//
//  VKLShaderTypes.h
//  VKLottie
//
//  Created by Антон Сергеев on 16.10.2019.
//

#ifndef VKLShaderTypes_h
#define VKLShaderTypes_h

typedef enum VKLVertexInputIndex {
    VKLVertexInputIndexVertices = 0,
} VKLVertexInputIndex;

typedef enum VKLFragmentInputIndex {
    VKLFragmentInputIndexEncodedBuffer = 0,
    VKLFragmentInputIndexEncodedBufferLength = 1,
    VKLFragmentInputIndexSize = 2,
} VKLFragmentInputIndex;

typedef struct {
    vector_float2 position;
} VKLVertex;

#endif /* VKLShaderTypes_h */
