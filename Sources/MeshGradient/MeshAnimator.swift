
import Foundation
import simd

/// Stores current and next state of the mesh. Used for animatable meshes
public final class MeshAnimator: MeshDataProvider {
    
	public struct Configuration {
		
		/// - Parameters:
		///   - framesPerSecond: Preferred framerate get that from MTKView
		///   - animationSpeedRange: Range of animation duration in the mesh, literally. The less the faster
		///   - meshRandomizer: Randomisation functions for mesh
		public init(framesPerSecond: Int = 60, animationSpeedRange: ClosedRange<TimeInterval> = 2...5, meshRandomizer: MeshRandomizer) {
			self.framesPerSecond = framesPerSecond
			self.animationSpeedRange = animationSpeedRange
			self.meshRandomizer = meshRandomizer
		}
		
		public var framesPerSecond: Int
		public var animationSpeedRange: ClosedRange<TimeInterval>
		public var meshRandomizer: MeshRandomizer
	}

    private struct AnimationFrameControlPoint {
        let finalControlPoint: ControlPoint
        let startPoint: ControlPoint
        var completionFactor: Double // 0...1
        let scaleFactor: Double
        
        mutating func bumpNextFrame() -> ControlPoint {
            completionFactor += scaleFactor
            var step = (finalControlPoint - startPoint)
            
            let easedCompletionFactor = completionFactor * completionFactor * (3 - 2 * completionFactor);
            step.scale(by: easedCompletionFactor)
            
            return startPoint + step
        }
        
        static var zero: AnimationFrameControlPoint {
            .init(finalControlPoint: .zero, startPoint: .zero, completionFactor: .zero, scaleFactor: .zero)
        }
    }
    
	private let initialGrid: Grid<ControlPoint>
    public var configuration: Configuration
	private var animationParameters: Grid<AnimationFrameControlPoint>
    
	public init(grid: Grid<ControlPoint>, configuration: Configuration) {
        self.initialGrid = grid
        self.configuration = configuration
        
        self.animationParameters = Grid<AnimationFrameControlPoint>(repeating: .zero, width: grid.width, height: grid.height)
        
        for y in 0 ..< animationParameters.height {
            for x in 0 ..< animationParameters.width {
				animationParameters[x, y] = generateNextAnimationEndpoint(x: x, y: y, gridWidth: grid.width, gridHeight: grid.height, startPoint: grid[x, y])
            }
        }
    }
    
    public var grid: Grid<ControlPoint> {
        var resultGrid = Grid<ControlPoint>(repeating: .zero,
                                            width: animationParameters.width,
                                            height: animationParameters.height)
        
        for y in 0 ..< animationParameters.height {
            for x in 0 ..< animationParameters.width {
                let i = animationParameters.index(x: x, y: y)
                resultGrid[i] = animationParameters[i].bumpNextFrame()
                if animationParameters[i].completionFactor >= 1 {
					animationParameters[i] = generateNextAnimationEndpoint(x: x, y: y, gridWidth: resultGrid.width, gridHeight: resultGrid.height, startPoint: resultGrid[i])
                }
            }
        }
        return resultGrid
    }
    
	private func generateNextAnimationEndpoint(x: Int, y: Int, gridWidth: Int, gridHeight: Int, startPoint: ControlPoint) -> AnimationFrameControlPoint {
		let animationDuration = Double.random(in: configuration.animationSpeedRange)
        let scaleFactor = (1 / Double(configuration.framesPerSecond)) / animationDuration
        var randomizedControlPoint = initialGrid[x, y]
        
		configuration.meshRandomizer.locationRandomizer(&randomizedControlPoint.location, x, y, gridWidth, gridHeight)
		
		configuration.meshRandomizer.turbulencyRandomizer(&randomizedControlPoint.uTangent, x, y, gridWidth, gridHeight)
		configuration.meshRandomizer.turbulencyRandomizer(&randomizedControlPoint.vTangent, x, y, gridWidth, gridHeight)
		
		configuration.meshRandomizer.colorRandomizer(&randomizedControlPoint.color, randomizedControlPoint.color, x, y, gridWidth, gridHeight)
        
        return AnimationFrameControlPoint(finalControlPoint: randomizedControlPoint,
                                          startPoint: startPoint,
                                          completionFactor: 0,
                                          scaleFactor: scaleFactor)
    }
    
}
