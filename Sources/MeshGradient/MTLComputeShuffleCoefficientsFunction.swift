
import Foundation
import Metal
import simd
@_implementationOnly import MeshGradientCHeaders

final class MTLComputeShuffleCoefficientsFunction {
    
    private let pipelineState: MTLComputePipelineState
    private let bufferPool: MTLBufferPool
    
    init(device: MTLDevice, library: MTLLibrary, bufferPool: MTLBufferPool) throws {
        guard let shuffleCoefficientsFunction = library.makeFunction(name: "shuffleCoefficients")
        else { throw MeshGradientError.metalFunctionNotFound(name: "shuffleCoefficients") }
        
        self.pipelineState = try device.makeComputePipelineState(function: shuffleCoefficientsFunction)
        self.bufferPool = bufferPool
    }
    
    func call(grid: Grid<ControlPoint>, intermediateResultBuffer: MTLBuffer, commandBuffer: MTLCommandBuffer) {
        let buffer = grid.elements.map {
            return MeshControlPoint(location: $0.location,
                                    uTangent: $0.uTangent,
                                    vTangent: $0.vTangent,
                                    color: vector_float4($0.color, 1))
        }
        
        let bufferLength = MemoryLayout<MeshControlPoint>.stride * buffer.count
        guard
            let computeEncoder = commandBuffer.makeComputeCommandEncoder(),
            let inputBuffer = bufferPool[bufferLength, .storageModeShared]
        else {
            assertionFailure()
            return
        }
        computeEncoder.setComputePipelineState(pipelineState)
        
        commandBuffer.addCompletedHandler { _ in
            self.bufferPool[bufferLength, .storageModeShared] = inputBuffer
        }
        
        let rawPointer = inputBuffer.contents()
        let typedPointer = rawPointer.bindMemory(to: MeshControlPoint.self, capacity: bufferLength)
        let bufferedPointer = UnsafeBufferPointer(start: typedPointer, count: buffer.count)
        let mutatingPointer = UnsafeMutableBufferPointer(mutating: bufferedPointer)
        
        for i in stride(from: 0, to: buffer.count, by: 1) {
            mutatingPointer[i] = buffer[i]
        }
        
        computeEncoder.setBuffer(inputBuffer,
                                 offset: 0,
                                 index: Int(ComputeMeshVertexInputIndexVertices.rawValue))
        
        var gridSize = vector_uint2(UInt32(grid.width), UInt32(grid.height))
        computeEncoder.setBytes(&gridSize,
                                length: MemoryLayout.size(ofValue: gridSize),
                                index: Int(ComputeMeshVertexInputIndexGridSize.rawValue))
        
        computeEncoder.setBuffer(intermediateResultBuffer,
                                 offset: 0,
                                 index: Int(ComputeMeshVertexInputIndexResult.rawValue))
        
        let computeSize = MTLSize(width: grid.width - 1,
                                  height: grid.height - 1,
                                  depth: 1)
        
        var calculationSizeParameter = SIMD2<Int32>(Int32(computeSize.width), Int32(computeSize.height))
        computeEncoder.setBytes(&calculationSizeParameter,
                                length: MemoryLayout.size(ofValue: calculationSizeParameter),
                                index: Int(ComputeMeshVertexInputCalculationSize.rawValue))
        
        let threadGroupSize = MTLSize(width: min(grid.elements.count, pipelineState.maxTotalThreadsPerThreadgroup),
                                      height: 1,
                                      depth: 1)
        
        computeEncoder.dispatchThreadgroups(computeSize,
                                            threadsPerThreadgroup: threadGroupSize)
        
        computeEncoder.endEncoding()
    }
    
}
