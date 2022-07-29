
#include <metal_stdlib>

#import "../MeshGradientCHeaders/include/MetalMeshShaderTypes.h"

using namespace metal;

static float4x4 meshXCoefficients(MeshControlPoint p00,
                                  MeshControlPoint p01,
                                  MeshControlPoint p10,
                                  MeshControlPoint p11) {
    
    return float4x4 {
        { p00.location.x, p10.location.x, p00.uTangent.x, p10.uTangent.x },
        { p01.location.x, p11.location.x, p01.uTangent.x, p11.uTangent.x },
        { p00.vTangent.x, p10.vTangent.x,              0,              0 },
        { p01.vTangent.x, p11.vTangent.x,              0,              0 },
    };
}

static float4x4 meshYCoefficients(MeshControlPoint p00,
                                  MeshControlPoint p01,
                                  MeshControlPoint p10,
                                  MeshControlPoint p11) {
    
    
    return float4x4 {
        { p00.location.y, p10.location.y, p00.uTangent.y, p10.uTangent.y },
        { p01.location.y, p11.location.y, p01.uTangent.y, p11.uTangent.y },
        { p00.vTangent.y, p10.vTangent.y,              0,              0 },
        { p01.vTangent.y, p11.vTangent.y,              0,              0 },
    };
}

static float4x4 colorCoefficients(float p00,
                                  float p01,
                                  float p10,
                                  float p11) {
    
    return float4x4 {
        { p00, p10,  0,  0 },
        { p01, p11,  0,  0 },
        {   0,   0,  0,  0 },
        {   0,   0,  0,  0 },
    };
}

MeshControlPoint meshControlPoint(device const MeshControlPoint* inVertices, uint x, uint y, uint width) {
    return inVertices[x + y * width];
}


kernel void shuffleCoefficients(device const MeshControlPoint* inVertices [[buffer(ComputeMeshVertexInputIndexVertices)]],
                                constant vector_uint2 *gridSize [[buffer(ComputeMeshVertexInputIndexGridSize)]],
                                device MeshIntermediateVertex* result [[buffer(ComputeMeshVertexInputIndexResult)]],
                                constant vector_uint2 *computeSize [[buffer(ComputeMeshVertexInputCalculationSize)]],
                                vector_uint2 index [[thread_position_in_grid]]) {
    vector_uint2 computeSizeValue = *computeSize;
    
    if (index.x >= computeSizeValue.x || index.y >= computeSizeValue.y) {
        return;
    }
    
    uint width = (*gridSize).x;
    
    uint x = index.x;
    uint y = index.y;
    
    uint i = index.x + index.y * (width - 1);
    
    MeshControlPoint p00 = meshControlPoint(inVertices,     x,     y, width);
    MeshControlPoint p01 = meshControlPoint(inVertices,     x, y + 1, width);
    MeshControlPoint p10 = meshControlPoint(inVertices, x + 1,     y, width);
    MeshControlPoint p11 = meshControlPoint(inVertices, x + 1, y + 1, width);
    
    float4x4 X = meshXCoefficients(p00, p01, p10, p11);
    float4x4 Y = meshYCoefficients(p00, p01, p10, p11);
    
    float4x4 R = colorCoefficients(p00.color.x,
                                   p01.color.x,
                                   p10.color.x,
                                   p11.color.x);
    
    float4x4 G = colorCoefficients(p00.color.y,
                                   p01.color.y,
                                   p10.color.y,
                                   p11.color.y);
    
    float4x4 B = colorCoefficients(p00.color.z,
                                   p01.color.z,
                                   p10.color.z,
                                   p11.color.z);
    
    MeshIntermediateVertex intermediateVertex = {
        X,
        Y,
        R,
        G,
        B,
        x,
        y,
    };
    result[i] = intermediateVertex;
}
