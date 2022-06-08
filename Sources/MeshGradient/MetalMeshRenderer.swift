
import Foundation
import Metal
import MetalKit
@_implementationOnly import MeshGradientCHeaders

public final class MetalMeshRenderer: NSObject, MTKViewDelegate {
	
	var commandQueue: MTLCommandQueue?
	var bufferPool: MTLBufferPool?
    
    var computeNoiseFunction: MTLComputeNoiseFunction?
    var computeShuffleCoefficients: MTLComputeShuffleCoefficientsFunction?
    var computeHermitPatchMatrix: MTLComputeHermitPatchMatrixFunction?
    var computeMeshTrianglePrimitives: MTLComputeMeshTrianglePrimitivesFunction?
    var drawMesh: MTLDrawMeshTrianglesFunction?
    
	var viewportSize: vector_float2 = .zero
	
	var subdivisions: Int
	let meshDataProvider: MeshDataProvider
    let grainAlpha: Float
	
    public init(metalKitView mtkView: MTKView, meshDataProvider: MeshDataProvider, grainAlpha: Float, subdivisions: Int = 18) {
		self.subdivisions = subdivisions
		self.meshDataProvider = meshDataProvider
        self.grainAlpha = grainAlpha
		
		guard let device = mtkView.device,
			  let defaultLibrary = try? device.makeDefaultLibrary(bundle: .module)
		else {
			assertionFailure()
			return
		}
		
        
        let bufferPool = MTLBufferPool(device: device)
		
		do {
            computeNoiseFunction = try .init(device: device, library: defaultLibrary)
            computeShuffleCoefficients = try .init(device: device, library: defaultLibrary, bufferPool: bufferPool)
            computeHermitPatchMatrix = try .init(device: device, library: defaultLibrary)
            computeMeshTrianglePrimitives = try .init(device: device, library: defaultLibrary)
            drawMesh = try .init(device: device, library: defaultLibrary, mtkView: mtkView)
            
		} catch {
			assertionFailure(error.localizedDescription)
		}
		commandQueue = device.makeCommandQueue()
        self.bufferPool = bufferPool
	}
	
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
		viewportSize.x = Float(size.width)
		viewportSize.y = Float(size.height)
	}
	
    private func calculateTriangles(grid: Grid<ControlPoint>, subdivisions: Int, commandBuffer: MTLCommandBuffer) -> (buffer: MTLBuffer, length: Int, elementsCount: Int)? {
		let resultVerticesSize = getResultVerticesSize(grid: grid, subdivisions: subdivisions)
		
		let resultTrianglesSize = (resultVerticesSize.width - 1) * (resultVerticesSize.height - 1) * 6
		let resultTrianglesBufferSize = MemoryLayout<MeshVertex>.stride * resultTrianglesSize
		
		guard let (triangleStripBuf, _, triangleStripCount) = calculateMeshTriangles(grid: grid, subdivisions: subdivisions, commandBuffer: commandBuffer),
			  let resultTrianglesBuffer = bufferPool?[resultTrianglesBufferSize, .storageModePrivate],
              let computeMeshTrianglePrimitives = self.computeMeshTrianglePrimitives
		else { return nil }
		commandBuffer.addCompletedHandler { _ in
			self.bufferPool?[resultTrianglesBufferSize, .storageModePrivate] = resultTrianglesBuffer
		}
        
        computeMeshTrianglePrimitives.call(gridSize: resultVerticesSize,
                                           resultTrianglesBuffer: resultTrianglesBuffer,
                                           finalVertices: triangleStripBuf,
                                           finalVerticesSize: triangleStripCount,
                                           commandBuffer: commandBuffer)
        return (resultTrianglesBuffer, resultTrianglesBufferSize, resultTrianglesSize)
	}
	
	private func getResultVerticesSize(grid: Grid<ControlPoint>, subdivisions: Int) -> (width: Int, height: Int) {
		return (width: (grid.width - 1) * subdivisions, height: (grid.height - 1) * subdivisions)
	}
	
    private func calculateMeshTriangles(grid: Grid<ControlPoint>, subdivisions: Int, commandBuffer: MTLCommandBuffer) -> (buffer: MTLBuffer, length: Int, elementsCount: Int)? {

		let resultVerticesSize = getResultVerticesSize(grid: grid, subdivisions: subdivisions)
		
		let intermediateSize = (grid.width - 1) * (grid.height - 1)
		let intermediateBufferSize = intermediateSize * MemoryLayout<MeshIntermediateVertex>.stride
		
		let finalVerticesSize = resultVerticesSize.width * resultVerticesSize.height
		let finalVerticesBufferSize = MemoryLayout<MeshVertex>.stride * finalVerticesSize
		
        guard let intermediateResultBuffer = bufferPool?[intermediateBufferSize, .storageModePrivate],
			  let finalVerticesBuffer = bufferPool?[finalVerticesBufferSize, .storageModePrivate],
              let computeShuffleCoefficients = self.computeShuffleCoefficients,
              let computeHermitPatchMatrix = self.computeHermitPatchMatrix
				
		else {
			assertionFailure()
			return nil
		}
		commandBuffer.addCompletedHandler { _ in
			self.bufferPool?[intermediateBufferSize, .storageModePrivate] = intermediateResultBuffer
			self.bufferPool?[finalVerticesBufferSize, .storageModePrivate] = finalVerticesBuffer
		}
		
		commandBuffer.label = "Show Mesh Buffer"
        
        computeShuffleCoefficients.call(grid: grid,
                                        intermediateResultBuffer: intermediateResultBuffer,
                                        commandBuffer: commandBuffer)
        
        
        computeHermitPatchMatrix.call(subdivisions: subdivisions,
                                      resultBuffer: finalVerticesBuffer,
                                      intermediateResultBuffer: intermediateResultBuffer,
                                      gridWidth: resultVerticesSize.width,
                                      intermediateResultBufferSize: intermediateSize,
                                      commandBuffer: commandBuffer)
        
        return (finalVerticesBuffer, finalVerticesBufferSize, finalVerticesSize)
	}
	
    public func draw(in view: MTKView) {
        guard let commandQueue = commandQueue,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeNoise = self.computeNoiseFunction
		else { return }
		let grid = meshDataProvider.grid
        
        let noiseTexture = computeNoise.call(viewportSize: viewportSize,
                                             pixelFormat: view.colorPixelFormat,
                                             commandQueue: commandQueue,
                                             uniforms: .init(isSmooth: 1,
                                                             color1: 94,
                                                             color2: 168,
                                                             color3: 147,
                                                             noiseAlpha: grainAlpha))
		
		guard let (resultBuffer, _, resultElementsCount) = calculateTriangles(grid: grid, subdivisions: subdivisions, commandBuffer: commandBuffer),
              let drawMesh = self.drawMesh
		else { assertionFailure(); return }
        
        drawMesh.call(meshVertices: resultBuffer,
                      noise: noiseTexture,
                      meshVerticesCount: resultElementsCount,
                      view: view,
                      commandBuffer: commandBuffer,
                      viewportSize: viewportSize)
        
        if let drawable = view.currentDrawable {
			commandBuffer.present(drawable)
		}
		
		commandBuffer.commit()
	}
	
	func unwrap<Element>(buffer: MTLBuffer, length: Int? = nil, elementsCount: Int) -> [Element] {
		let rawPointer = buffer.contents()
		let length = length ?? MemoryLayout<Element>.stride * elementsCount
		let typedPointer = rawPointer.bindMemory(to: Element.self, capacity: length)
		let bufferedPointer = UnsafeBufferPointer(start: typedPointer, count: length)
		
		var result: [Element] = []
		for i in 0..<elementsCount {
			result.append(bufferedPointer[i])
		}
		return result
	}
	
}
