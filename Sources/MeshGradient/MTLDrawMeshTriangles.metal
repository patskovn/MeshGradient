
#include <metal_stdlib>
using namespace metal;

#import "../MeshGradientCHeaders/include/MetalMeshShaderTypes.h"

// Vertex shader outputs and fragment shader inputs
struct RasterizerData
{
	// The [[position]] attribute of this member indicates that this value
	// is the clip space position of the vertex when this structure is
	// returned from the vertex function.
	float4 position [[position]];
	
	// Since this member does not have a special attribute, the rasterizer
	// interpolates its value with the values of the other triangle vertices
	// and then passes the interpolated value to the fragment shader for each
	// fragment in the triangle.
	float4 color;
    float2 textureCoordinate;
};

vertex RasterizerData
prepareToDrawShader(uint vertexID [[vertex_id]],
					constant MeshVertex *vertices [[buffer(0)]])
{
	RasterizerData out;
	
	out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
	out.position.xy = vertices[vertexID].position.xy;
	
	// Pass the input color directly to the rasterizer.
	out.color = vertices[vertexID].color;
    
    out.textureCoordinate = float2(out.position.x / 2 + 0.5, -out.position.y / 2 + 0.5);
	
	return out;
}

fragment float4 drawRasterizedMesh(RasterizerData in [[stage_in]],
                                   texture2d<half> noiseTexture [[ texture(DrawMeshTextureIndexBaseColor) ]])
{
    
    
    constexpr sampler linear(coord::normalized,
                             address::clamp_to_edge,
                             filter::linear);
    
    // Sample the texture to obtain a color
    const float4 colorSample = float4(noiseTexture.sample(linear, in.textureCoordinate));
    
    const float3 outRGB = colorSample.w * colorSample.xyz + (1 - colorSample.w) * in.color.xyz;
    
	return float4(outRGB, in.color.w);
}
