#include <metal_stdlib>

#import "../MeshGradientCHeaders/include/MetalMeshShaderTypes.h"

using namespace metal;

static vector_float2 surfacePoint(float u,
                                  float v,
                                  float4x4 H,
                                  float4x4 H_T,
                                  float4x4 X,
                                  float4x4 Y) {
    float4 U = float4 {
        u * u * u, u * u, u, 1
    };
    float4 V = float4 {
        v * v * v, v * v, v, 1
    };
    
    return float2 {
        dot(V, U * H * X * H_T),
        dot(V, U * H * Y * H_T)
    };
}

static vector_float4 colorPoint(float u,
                                float v,
                                float4x4 H,
                                float4x4 H_T,
                                float4x4 R,
                                float4x4 G,
                                float4x4 B) {
    
    float4 U = float4 {
        u * u * u, u * u, u, 1
    };
    float4 V = float4 {
        v * v * v, v * v, v, 1
    };
    
    return float4 {
        dot(V, U * H * R * H_T),
        dot(V, U * H * G * H_T),
        dot(V, U * H * B * H_T),
        1
    };
}

kernel void computeHermitPatchMatrix(device const MeshIntermediateVertex* inVertices [[buffer(ComputeMeshFinalInputIndexVertices)]],
                                     constant uint *width [[buffer(ComputeMeshFinalInputIndexWidth)]],
                                     constant uint *subdivisions [[buffer(ComputeMeshFinalInputIndexSubdivisions)]],
                                     device MeshVertex* result [[buffer(ComputeMeshFinalInputIndexResult)]],
                                     constant vector_uint3 *computeSize [[buffer(ComputeMeshFinalInputIndexCalculationSize)]],
                                     vector_uint3 index [[thread_position_in_grid]]) {
    
    vector_uint3 computeSizeValue = *computeSize;
    
    if (index.x >= computeSizeValue.x || index.y >= computeSizeValue.y || index.z >= computeSizeValue.z) {
        return;
    }
    
    uint w = *width;
    uint s = *subdivisions;
    
    uint i = index.z;
    
    uint u_i = index.y;
    uint v_i = index.x;
    
    MeshIntermediateVertex vert = inVertices[i];
    uint resX = vert.x * s + u_i;
    uint resY = vert.y * s + v_i;
    uint resI = resX + resY * w;
    
    float u = float(u_i) / float(s-1);
    float v = float(v_i) / float(s-1);
    
    float4x4 H = float4x4 {
        {  2, -3,  0,  1 },
        { -2,  3,  0,  0 },
        {  1, -2,  1,  0 },
        {  1, -1,  0,  0 },
    };
    float4x4 H_T = transpose(H);
    
    MeshVertex resultVertex = {
        surfacePoint(u, v, H, H_T, vert.X, vert.Y),
        colorPoint(u, v, H, H_T, vert.R, vert.G, vert.B),
    };
    result[resI] = resultVertex;
}
