//
//  VKLShaderTypes.h
//  VKLottie
//
//  Created by Антон Сергеев on 16.10.2019.
//

//#ifndef VKLShaderTypes_h
//#define VKLShaderTypes_h

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

typedef enum VKLKernelInputIndex {
    VKLKernelInputIndexDecodedBuffer,
    VKLKernelInputIndexPreviousYBuffer,
    VKLKernelInputIndexPreviousUBuffer,
    VKLKernelInputIndexPreviousVBuffer,
    VKLKernelInputIndexPreviousABuffer,
    VKLKernelInputIndexEncodedYBuffer,
    VKLKernelInputIndexEncodedUBuffer,
    VKLKernelInputIndexEncodedVBuffer,
    VKLKernelInputIndexEncodedABuffer,
    VKLKernelInputIndexSize,
    VKLKernelInputIndexScale,
} VKLKernelInputIndex;

//#endif /* VKLShaderTypes_h */
