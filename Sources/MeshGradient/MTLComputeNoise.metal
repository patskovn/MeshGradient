
#include <metal_stdlib>

#import "../MeshGradientCHeaders/include/MetalMeshShaderTypes.h"

using namespace metal;


constant uint NOISE_DIM = 512;

// Noise Declarations
float rand(int x, int y);
float smoothNoise(float x, float y);

half4 noiseColor(int x, int y, bool isSmooth, float alpha);

// The Kernel
kernel void computeNoize(texture2d<half, access::write> outTexture [[texture(ComputeNoiseInputIndexOutputTexture)]],
                         constant NoiseUniforms &uniforms [[buffer(ComputeNoiseInputIndexUniforms)]],
                         uint2 gid [[thread_position_in_grid]])
{
    half4 outColor = noiseColor(gid.x,
                                gid.y,
                                uniforms.isSmooth == 1,
                                uniforms.noiseAlpha);
    
    outTexture.write(outColor, gid);
}

// Noise
half4 noiseColor(int x, int y, bool isSmooth, float alpha)
{
    float colorVal;
    
    float xVal = x;
    float yVal = y;
    
    float xZoomed = xVal / 0.5;
    float yZoomed = yVal / 0.5;
    
    colorVal = 256.0 * rand(xZoomed, yZoomed);
    
    if (isSmooth) {
//        colorVal = 256.0 * smoothNoise(xZoomed, yZoomed);
    }
    
    return half4(half(colorVal) / 255.0, half(colorVal) / 255.0, half(colorVal) / 255.0, alpha);
}

// Noise Functions
float smoothNoise(float x, float y)
{
    // Get the truncated x, y, and z values
    int intX = x;
    int intY = y;
    
    // Get the fractional reaminder of x, y, and z
    float fractX = x - intX;
    float fractY = y - intY;
    
    // Get first whole number before
    int x1 = (intX + NOISE_DIM) % NOISE_DIM;
    int y1 = (intY + NOISE_DIM) % NOISE_DIM;
    
    // Get the number after
    int x2 = (x1 + NOISE_DIM - 1) % NOISE_DIM;
    int y2 = (y1 + NOISE_DIM - 1) % NOISE_DIM;
    
    // interpolate the noise
    float value = 0.0;
    value += fractX       * fractY       * rand(x1,y1);
    value += fractX       * (1 - fractY) * rand(x1,y2);
    value += (1 - fractX) * fractY       * rand(x2,y1);
    value += (1 - fractX) * (1 - fractY) * rand(x2,y2);
    
    return value;
}

// Generate a random float in the range [0.0f, 1.0f] using x, y, and z (based on the xor128 algorithm)
float rand(int x, int y)
{
    int seed = x + y * 57 * 241;
    seed = (seed<< 13) ^ seed;
    return (( 1.0 - ( (seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
}







