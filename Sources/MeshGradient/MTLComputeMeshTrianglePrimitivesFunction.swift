
import Foundation
import Metal
import simd
@_implementationOnly import MeshGradientCHeaders

final class MTLComputeMeshTrianglePrimitivesFunction {
    
    private let pipelineState: MTLComputePipelineState
    
    init(device: MTLDevice, library: MTLLibrary) throws {
        guard let computeMeshTrianglePrimitivesFunction = library.makeFunction(name: "computeMeshTrianglePrimitives")
        else { throw MeshGradientError.metalFunctionNotFound(name: "computeMeshTrianglePrimitives") }
        
        self.pipelineState = try device.makeComputePipelineState(function: computeMeshTrianglePrimitivesFunction)
    }
    
    func call(gridSize: (width: Int, height: Int),
              resultTrianglesBuffer: MTLBuffer,
              finalVertices: MTLBuffer,
              finalVerticesSize: Int,
              commandBuffer: MTLCommandBuffer) {
        
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder()
        else {
            assertionFailure()
            return
        }
        computeEncoder.setComputePipelineState(pipelineState)
        
        computeEncoder.setBuffer(finalVertices,
                                 offset: 0,
                                 index: Int(ComputeMeshTrianglesIndexVertices.rawValue))
        
        var (width, height) = gridSize
        computeEncoder.setBytes(&width,
                                length: MemoryLayout.size(ofValue: width),
                                index: Int(ComputeMeshTrianglesIndexWidth.rawValue))
        
        computeEncoder.setBytes(&height,
                                length: MemoryLayout.size(ofValue: height),
                                index: Int(ComputeMeshTrianglesIndexHeight.rawValue))
        
        computeEncoder.setBuffer(resultTrianglesBuffer,
                                 offset: 0,
                                 index: Int(ComputeMeshTrianglesIndexResult.rawValue))
        
        let computeSize = MTLSize(width: width - 1,
                                  height: height - 1,
                                  depth: 1)
        
        var calculationSizeParameter = SIMD2<Int32>(Int32(computeSize.width), Int32(computeSize.height))
        computeEncoder.setBytes(&calculationSizeParameter,
                                length: MemoryLayout.size(ofValue: calculationSizeParameter),
                                index: Int(ComputeMeshTrianglesIndexCalculationSize.rawValue))
        
        let threadGroupSize = MTLSize(width: min(finalVerticesSize, pipelineState.maxTotalThreadsPerThreadgroup),
                                      height: 1,
                                      depth: 1)
        
        computeEncoder.dispatchThreadgroups(computeSize,
                                            threadsPerThreadgroup: threadGroupSize)
        
        computeEncoder.endEncoding()
    }
}
