
import Foundation
import Metal
import MetalKit
import simd
@_implementationOnly import MeshGradientCHeaders

final class MTLDrawMeshTrianglesFunction {
    
    private let pipelineState: MTLRenderPipelineState
    
    init(device: MTLDevice, library: MTLLibrary, mtkView: MTKView) throws {
        guard let prepareToDrawFunction = library.makeFunction(name: "prepareToDrawShader")
        else { throw MeshGradientError.metalFunctionNotFound(name: "prepareToDrawShader") }
        
        guard let drawMeshFunction = library.makeFunction(name: "drawRasterizedMesh")
        else { throw MeshGradientError.metalFunctionNotFound(name: "drawRasterizedMesh") }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "Draw mesh pipeline"
        pipelineDescriptor.vertexFunction = prepareToDrawFunction
        pipelineDescriptor.fragmentFunction = drawMeshFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        
        self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func call(meshVertices: MTLBuffer,
              noise: MTLTexture?,
              meshVerticesCount: Int,
              view: MTKView,
              commandBuffer: MTLCommandBuffer,
              viewportSize: simd_float2) {
        
        assert(meshVerticesCount.isMultiple(of: 3))
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else {
            assertionFailure()
            return
        }
        
        renderEncoder.setViewport(
            MTLViewport(originX: 0,
                        originY: 0,
                        width: Double(viewportSize.x),
                        height: Double(viewportSize.y),
                        znear: 0,
                        zfar: 1)
        )
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        renderEncoder.setFragmentTexture(noise,
                                         index: Int(DrawMeshTextureIndexBaseColor.rawValue))
        
        renderEncoder.setVertexBuffer(meshVertices,
                                      offset: 0,
                                      index: 0)
        for i in stride(from: 0, to: meshVerticesCount, by: 3) {
            renderEncoder.drawPrimitives(type: .triangle,
                                         vertexStart: i,
                                         vertexCount: 3)
        }
        
        renderEncoder.endEncoding()
    }
}
