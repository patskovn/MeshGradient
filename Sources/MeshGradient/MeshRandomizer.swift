
import Foundation
import simd

/// Stores randimisation information of the mesh. Data can be dynamically changes in SwiftUI views.
/// Default initialiser provides empirically good random mesh. Free to change for your own needs.
public struct MeshRandomizer {
	public init(locationRandomizer: @escaping MeshRandomizer.LocationRandomizer = MeshRandomizer.automaticallyRandomizeLocationYExceptTopAndBottomBasedOnGridSize(),
				turbulencyRandomizer: @escaping MeshRandomizer.TangentRandomizer = MeshRandomizer.randomizeTurbulencyExceptEdges(range: -0.25...0.25),
				colorRandomizer: @escaping MeshRandomizer.ColorRandomizer = MeshRandomizer.arrayBasedColorRandomizer(availableColors: (0...15).map({ _ in MeshRandomizer.randomColor() }))) {
		self.locationRandomizer = locationRandomizer
		self.turbulencyRandomizer = turbulencyRandomizer
		self.colorRandomizer = colorRandomizer
	}
	
	public typealias LocationRandomizer = (_ location: inout simd_float2, _ x: Int, _ y: Int, _ gridWidth: Int, _ gridHeight: Int) -> Void
	public typealias TangentRandomizer = (_ tangent: inout simd_float2, _ x: Int, _ y: Int, _ gridWidth: Int, _ gridHeight: Int) -> Void
	public typealias ColorRandomizer = (_ color: inout simd_float3, _ initialColor: simd_float3, _ x: Int, _ y: Int, _ gridWidth: Int, _ gridHeight: Int) -> Void
	
	
	public var locationRandomizer: LocationRandomizer
	public var turbulencyRandomizer: TangentRandomizer
	public var colorRandomizer: ColorRandomizer
	
	
	public static func randomColor() -> simd_float3 {
		.init(.random(in: 0...1), .random(in: 0...1), .random(in: 0...1))
	}
	
	/// Will randomly choose colors from the provided array
	/// - Parameter availableColors: List of colors that will be used for randomisation
	public static func arrayBasedColorRandomizer(availableColors: [simd_float3]) -> ColorRandomizer {
		assert(!availableColors.isEmpty, "Available colors can not be empty")
		return { color, _, _, _, _, _ in
			color = availableColors.randomElement()!
		}
	}
	
	/// Slightly changes Y location of the control points based on grid width and height.
	/// Grid is drawed from top to bottom, and because of that changing of X locations can create visual glitches
	public static func automaticallyRandomizeLocationYExceptTopAndBottomBasedOnGridSize() -> LocationRandomizer {
		return { location, x, y, gridWidth, gridHeight in
			let locationVariationRange = 1.2 * 1 / Float(gridHeight)
			if y != 0 && y != gridHeight - 1 {
				location.y += .random(in: -locationVariationRange...locationVariationRange)
			}
		}
	}
	
	/// Applies random values from range to each control point location. Avoids randomisation of control points on the edges
	/// - Parameter range: Range for randomisation
	public static func randomizeLocationExceptEdges(range: ClosedRange<Float>) -> LocationRandomizer {
		return { location, x, y, gridWidth, gridHeight in
			if x != 0 && x != gridWidth - 1 {
				location.x += .random(in: range)
			}
			if y != 0 && y != gridHeight - 1 {
				location.y += .random(in: range)
			}
		}
	}
	
	/// Applies random values from range for each control point tangents. Avoids randomisation of control points on the edges
	/// - Parameter range: Range for randomisation
	public static func randomizeTurbulencyExceptEdges(range: ClosedRange<Float>) -> TangentRandomizer {
		return { tangent, x, y, width, height in
			if (x != 0 && y != 0) && (x != width - 1 && y != height - 1) {
				tangent.x += .random(in: range)
				tangent.y += .random(in: range)
			}
		}
	}
}
