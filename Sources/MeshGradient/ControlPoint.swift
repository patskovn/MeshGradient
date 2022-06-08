
import Foundation
import simd
import SwiftUI

/// Describes one mesh gradient entry in matrix.
public struct ControlPoint {
    
	/// Color of the control point
    public var color: simd_float3
	
	/// Location of control point. Initially just interpolated from grid size. Change it to have overlapping in mesh
    public var location: simd_float2
	
	/// Defines turbulency in mesh gradient. Change to show more "sinusoidal" look
    public var uTangent: simd_float2
	
	/// Defines turbulency in mesh gradient. Change to show more "sinusoidal" look
    public var vTangent: simd_float2
    
    public init(color: simd_float3 = simd_float3(0, 0, 0),
                location: simd_float2 = simd_float2(0, 0),
                uTangent: simd_float2 = simd_float2(0, 0),
                vTangent: simd_float2 = simd_float2(0, 0)) {
        self.color = color
        self.location = location
        self.uTangent = uTangent
        self.vTangent = vTangent
    }
    
}

extension ControlPoint: VectorArithmetic, AdditiveArithmetic {
    public static func - (lhs: ControlPoint, rhs: ControlPoint) -> ControlPoint {
        .init(color: lhs.color - rhs.color,
              location: lhs.location - rhs.location,
              uTangent: lhs.uTangent - rhs.uTangent,
              vTangent: lhs.vTangent - rhs.vTangent)
    }
    
    public static func + (lhs: ControlPoint, rhs: ControlPoint) -> ControlPoint {
        .init(color: lhs.color + rhs.color,
              location: lhs.location + rhs.location,
              uTangent: lhs.uTangent + rhs.uTangent,
              vTangent: lhs.vTangent + rhs.vTangent)
    }
    
    public mutating func scale(by rhs: Double) {
        color.scale(by: rhs)
        location.scale(by: rhs)
        uTangent.scale(by: rhs)
        vTangent.scale(by: rhs)
    }
    
    public var magnitudeSquared: Double {
        color.magnitudeSquared + location.magnitudeSquared + uTangent.magnitudeSquared + vTangent.magnitudeSquared
    }
    
    public static var zero: ControlPoint {
        .init(color: .zero, location: .zero, uTangent: .zero, vTangent: .zero)
    }
}
