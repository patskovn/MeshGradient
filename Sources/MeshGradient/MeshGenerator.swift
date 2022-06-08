
import Foundation

import simd

public enum MeshGenerator {
	
	public typealias Color = simd_float3
	
	/// Linear interpolation between `min` and `max`.
	private static func lerp<S: SignedNumeric>(_ f: S, _ min: S, _ max: S) -> S {
		min + f * (max - min)
	}
	
	public static func generate(colorDistribution: Grid<Color>) -> Grid<ControlPoint> {
		var grid = Grid(repeating: ControlPoint(),
						width: colorDistribution.width,
						height: colorDistribution.height)
		
		for y in 0 ..< grid.height {
			for x in 0 ..< grid.width {
				generateControlPoint(in: &grid, x: x, y: y)
			}
		}
		return grid
	}
	
	private static func generateControlPoint(in grid: inout Grid<ControlPoint>, x: Int, y: Int) {
		grid[x, y].location = simd_float2(
			lerp(Float(x) / Float(grid.width  - 1), -1, 1),
			lerp(Float(y) / Float(grid.height - 1), -1, 1)
		)
		
		grid[x, y].uTangent.x = 2 / Float(grid.width  - 1)
		grid[x, y].vTangent.y = 2 / Float(grid.height - 1)
	}
}

#if canImport(UIKit)
import UIKit
typealias NativeColor = UIColor
#elseif canImport(AppKit)
import AppKit
typealias NativeColor = NSColor
#endif

public extension NativeColor {
	var toSIMD3: simd_float3 {
		
		var r: CGFloat = 0
		var g: CGFloat = 0
		var b: CGFloat = 0
		var o: CGFloat = 0
		
		getRed(&r, green: &g, blue: &b, alpha: &o)
		
		return .init(Float(r), Float(g), Float(b))
	}
}
