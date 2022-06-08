
#include <metal_stdlib>

#import "../MeshGradientCHeaders/include/MetalMeshShaderTypes.h"

using namespace metal;

MeshVertex meshVertex(device const MeshVertex* inVertices, uint x, uint y, uint width, uint tag) {
	return inVertices[x + y * width];
};

kernel void computeMeshTrianglePrimitives(device const MeshVertex* inVertices [[buffer(ComputeMeshTrianglesIndexVertices)]],
										  constant uint *width [[buffer(ComputeMeshTrianglesIndexWidth)]],
										  constant uint *height [[buffer(ComputeMeshTrianglesIndexHeight)]],
										  device MeshVertex* result [[buffer(ComputeMeshTrianglesIndexResult)]],
										  constant vector_uint2 *computeSize [[buffer(ComputeMeshTrianglesIndexCalculationSize)]],
										  vector_uint2 index [[thread_position_in_grid]]) {
	vector_uint2 computeSizeValue = *computeSize;
	
	if (index.x >= computeSizeValue.x || index.y >= computeSizeValue.y) {
		return;
	}
	
	uint w = *width;
	
	uint y = index.y;
	uint x = index.x;
	
	uint i = (x + y * (w - 1)) * 6;
	
	MeshVertex p00 = meshVertex(inVertices, x    , y    , w, 0);
	MeshVertex p10 = meshVertex(inVertices, x + 1, y    , w, 10);
	MeshVertex p01 = meshVertex(inVertices, x    , y + 1, w, 1);
	MeshVertex p11 = meshVertex(inVertices, x + 1, y + 1, w, 11);
	
	result[i+0] = p00;
	result[i+1] = p10;
	result[i+2] = p11;
	
	result[i+3] = p11;
	result[i+4] = p01;
	result[i+5] = p00;
}


