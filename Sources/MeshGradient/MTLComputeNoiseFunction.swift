

import Foundation
import Metal
import simd
@_implementationOnly import MeshGradientCHeaders

final class MTLComputeNoiseFunction {
    
    private var _noiseTexture: MTLTexture?
    
    private let device: MTLDevice
    private let pipelineState: MTLComputePipelineState
    
    init(device: MTLDevice, library: MTLLibrary) throws {
        self.device = device
        
        guard let computeNoiseFunction = library.makeFunction(name: "computeNoize")
        else { throw MeshGradientError.metalFunctionNotFound(name: "computeNoize") }
        
        self.pipelineState = try device.makeComputePipelineState(function: computeNoiseFunction)
    }
    
    func call(viewportSize: simd_float2, pixelFormat: MTLPixelFormat, commandQueue: MTLCommandQueue, uniforms: NoiseUniforms) -> MTLTexture? {
        guard uniforms.noiseAlpha > 0 else { return nil }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return nil }
        let width = Int(viewportSize.x)
        let height = Int(viewportSize.y)

        if width == 0 || height == 0 {
            return nil
        }
        
        if let noiseTexture = _noiseTexture, noiseTexture.width == width, noiseTexture.height == height {
            return noiseTexture
        }
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat,
                                                                         width: width,
                                                                         height: height,
                                                                         mipmapped: false)
        textureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget, .pixelFormatView]
        guard let noiseTexture = device.makeTexture(descriptor: textureDescriptor),
              let encoder = commandBuffer.makeComputeCommandEncoder()
        else { return nil }
        
        let threadgroupCounts = MTLSize(width: 8, height: 8, depth: 1)
        let threadgroups = MTLSize(width: noiseTexture.width / threadgroupCounts.width,
                                   height: noiseTexture.height / threadgroupCounts.height,
                                   depth: 1)
        
        encoder.setComputePipelineState(pipelineState)

        encoder.setTexture(noiseTexture, index: Int(ComputeNoiseInputIndexOutputTexture.rawValue))

        var uniforms = uniforms
        encoder.setBytes(&uniforms,
                         length: MemoryLayout.size(ofValue: uniforms),
                         index: Int(ComputeNoiseInputIndexUniforms.rawValue))

        encoder.dispatchThreadgroups(threadgroups,
                                     threadsPerThreadgroup: threadgroupCounts)

        encoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        self._noiseTexture = noiseTexture
        return noiseTexture
    }
    
}
extension MTLTexture {
    func getPixels<T>(mipmapLevel: Int = 0) -> UnsafeMutablePointer<T> {
        let fromRegion  = MTLRegionMake2D(0, 0, self.width, self.height)
        let bytesPerRow = 4 * self.width
        let data        = UnsafeMutablePointer<T>.allocate(capacity: bytesPerRow * self.height)
        
        self.getBytes(data, bytesPerRow: bytesPerRow, from: fromRegion, mipmapLevel: mipmapLevel)
        return data
    }
}
