//
//  UVTransform.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 7/5/26.
//

import UIKit
import MetalKit

typealias TextureMapping = UVTransform

/// A 2D affine transform for normalized texture coordinates ("UVs").
///
/// UV convention used throughout this project:
/// - `u` increases left-to-right from 0 to 1
/// - `v` increases top-to-bottom from 0 to 1 (top-left origin)
///
/// The transform is applied as:
/// `uv' = matrix * uv + offset`
struct UVTransform {
    let matrix: simd_float2x2
    let offset: SIMD2<Float>
    
    init(matrix: simd_float2x2 = .init(columns: ([1.0, 0.0], [0.0, 1.0])),
         offset: SIMD2<Float> = .zero) {
        self.matrix = matrix
        self.offset = offset
    }
    
    func apply(_ uv: SIMD2<Float>) -> SIMD2<Float> {
        matrix * uv + offset
    }

    /// Returns a transform equivalent to applying `self`, then applying `other`.
    ///
    /// If `self` is `uv1 = M1 * uv + b1` and `other` is `uv2 = M2 * uv1 + b2`,
    /// the result is `uv2 = (M2 * M1) * uv + (M2 * b1 + b2)`.
    func concatenating(_ other: UVTransform) -> UVTransform {
        UVTransform(
            matrix: other.matrix * matrix,
            offset: other.matrix * offset + other.offset
        )
    }
    
    // MARK: - Common UV transforms
    // Each definition is also shown as (u, v) -> (u', v') for readability.
    
    /// Identity: (u, v) -> (u, v)
    static let identity = UVTransform()
    
    /// Vertical flip: (u, v) -> (u, 1 - v)
    static let flippedVertical = UVTransform(matrix: .init(columns: ([1.0, 0.0], [0.0, -1.0])), offset: [0.0, 1.0])
    
    /// Horizontal flip: (u, v) -> (1 - u, v)
    static let flippedHorizontal = UVTransform(matrix: .init(columns: ([-1.0, 0.0], [0.0, 1.0])), offset: [1.0, 0.0])
    
    /// 180° rotation: (u, v) -> (1 - u, 1 - v)
    static let rotate180 = UVTransform(matrix: .init(columns: ([-1.0, 0.0], [0.0, -1.0])), offset: [1.0, 1.0])
    
    /// 90° clockwise rotation: (u, v) -> (1 - v, u)
    static let rotate90Clockwise = UVTransform(matrix: .init(columns: ([0.0, -1.0], [1.0, 0.0])), offset: [1.0, 0.0])
    
    /// 90° counter-clockwise rotation: (u, v) -> (v, 1 - u)
    static let rotate90CounterClockwise = UVTransform(matrix: .init(columns: ([0.0, 1.0], [-1.0, 0.0])), offset: [0.0, 1.0])
}

extension UIImage.Orientation {
    
    /// Maps UIKit image-orientation metadata to a UV transform.
    ///
    /// `UIImage` can represent orientation via metadata instead of modifying pixel order.
    /// When you create a texture from `cgImage`, you get the raw pixel buffer, so the
    /// on-screen result may appear rotated/flipped compared to how UIKit would display it.
    ///
    /// Applying this mapping to your quad UVs fixes that at draw time.
    var textureMapping: TextureMapping {
        switch self {
            case .up: return .identity
            case .down: return .rotate180
            case .left: return .rotate90CounterClockwise
            case .right: return .rotate90Clockwise
            case .upMirrored: return .flippedHorizontal
            case .downMirrored: return .rotate180.concatenating(.flippedHorizontal)
            case .leftMirrored: return .rotate90CounterClockwise.concatenating(.flippedHorizontal)
            case .rightMirrored: return .rotate90Clockwise.concatenating(.flippedHorizontal)
            @unknown default:
                return .identity
        }
    }
}
