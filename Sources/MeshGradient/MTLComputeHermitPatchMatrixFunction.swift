
import Foundation
import Metal
import simd
@_implementationOnly import MeshGradientCHeaders

final class MTLComputeHermitPatchMatrixFunction {
    
    private let pipelineState: MTLComputePipelineState
    
    init(device: MTLDevice, library: MTLLibrary) throws {
        guard let computeHermitPatchMatrixFunction = library.makeFunction(name: "computeHermitPatchMatrix")
        else { throw MeshGradientError.metalFunctionNotFound(name: "computeHermitPatchMatrix") }
        
        self.pipelineState = try device.makeComputePipelineState(function: computeHermitPatchMatrixFunction)
    }
    
    func call(subdivisions: Int,
              resultBuffer: MTLBuffer,
              intermediateResultBuffer: MTLBuffer,
              gridWidth: Int,
              intermediateResultBufferSize: Int,
              commandBuffer: MTLCommandBuffer) {
        
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder()
        else {
            assertionFailure()
            return
        }
        computeEncoder.setComputePipelineState(pipelineState)
        
        computeEncoder.setBuffer(intermediateResultBuffer,
                                 offset: 0,
                                 index: Int(ComputeMeshFinalInputIndexVertices.rawValue))
        
        var width = gridWidth
        let depth = intermediateResultBufferSize
        
        computeEncoder.setBytes(&width,
                                length: MemoryLayout.size(ofValue: width),
                                index: Int(ComputeMeshFinalInputIndexWidth.rawValue))
        
        var inSubdivisions = UInt32(subdivisions)
        computeEncoder.setBytes(&inSubdivisions,
                                length: MemoryLayout.size(ofValue: inSubdivisions),
                                index: Int(ComputeMeshFinalInputIndexSubdivisions.rawValue))
        
        computeEncoder.setBuffer(resultBuffer,
                                 offset: 0,
                                 index: Int(ComputeMeshFinalInputIndexResult.rawValue))
        
        let computeSize = MTLSize(width: subdivisions,
                                  height: subdivisions,
                                  depth: depth)
        
        var calculationSizeParameter = SIMD3<Int32>(Int32(computeSize.width),
                                                    Int32(computeSize.height),
                                                    Int32(computeSize.depth))
        
        computeEncoder.setBytes(&calculationSizeParameter,
                                length: MemoryLayout.size(ofValue: calculationSizeParameter),
                                index: Int(ComputeMeshFinalInputIndexCalculationSize.rawValue))
        
        let threadGroupSize = MTLSize(width: min(intermediateResultBufferSize, pipelineState.maxTotalThreadsPerThreadgroup),
                                      height: 1,
                                      depth: 1)
        
        computeEncoder.dispatchThreadgroups(computeSize,
                                            threadsPerThreadgroup: threadGroupSize)
        
        computeEncoder.endEncoding()
    }
    
}
