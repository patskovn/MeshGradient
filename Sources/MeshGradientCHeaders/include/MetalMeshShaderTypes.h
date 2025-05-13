//
//  MetalMeshShaderTypes.h
//  ConvettiEmitter
//
//  Created by Nikita Patskov on 03/06/2022.
//

#ifndef MetalMeshShaderTypes_h
#define MetalMeshShaderTypes_h

#include <simd/simd.h>
// Buffer index values shared between shader and C code to ensure Metal shader buffer inputs
// match Metal API buffer set calls.
typedef enum ComputeNoiseInputIndex
{
    ComputeNoiseInputIndexOutputTexture     = 0,
    ComputeNoiseInputIndexUniforms
} AAPLVertexInputIndex;

typedef enum ComputeMeshVertexInputIndex
{
    ComputeMeshVertexInputIndexVertices      = 0,
    ComputeMeshVertexInputIndexGridSize,
    ComputeMeshVertexInputIndexResult,
	ComputeMeshVertexInputCalculationSize,
} ComputeMeshVertexInputIndex;

typedef enum ComputeMeshFinalInputIndex
{
    ComputeMeshFinalInputIndexVertices      = 0,
    ComputeMeshFinalInputIndexWidth,
    ComputeMeshFinalInputIndexDepth,
    ComputeMeshFinalInputIndexSubdivisions,
    ComputeMeshFinalInputIndexResult,
	ComputeMeshFinalInputIndexCalculationSize,
    
} ComputeMeshFinalInputIndex;

typedef enum ComputeMeshTrianglesIndex
{
    ComputeMeshTrianglesIndexVertices      = 0,
    ComputeMeshTrianglesIndexWidth,
    ComputeMeshTrianglesIndexHeight,
    ComputeMeshTrianglesIndexResult,
	ComputeMeshTrianglesIndexCalculationSize,
} ComputeMeshTrianglesIndex;

typedef enum DrawMeshTextureIndex
{
    DrawMeshTextureIndexBaseColor = 0,
} DrawMeshTextureIndex;

struct NoiseUniforms
{
    int isSmooth;
    float color1;
    float color2;
    float color3;
    float noiseAlpha;
};

typedef struct
{
    vector_float2 location;
    vector_float2 uTangent;
    vector_float2 vTangent;
    
    vector_float4 color;
    
} MeshControlPoint;

typedef struct
{
    simd_float4x4 X;
    simd_float4x4 Y;
    
    simd_float4x4 R;
    simd_float4x4 G;
    simd_float4x4 B;
    
    unsigned int x;
    unsigned int y;
    
} MeshIntermediateVertex;

typedef struct
{
    vector_float2 position;
    vector_float4 color;
} MeshVertex;


#endif /* MetalMeshShaderTypes_h */
