//
//  ImageFilterConfig.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 9/5/26.
//

import Metal

protocol ImageFilterConfig {
    func encode(into encoder: MTLComputeCommandEncoder)
}

protocol Scalar: BitwiseCopyable, Comparable {}
extension Float: Scalar {}
extension UInt: Scalar {}

protocol ScalarConfig: ImageFilterConfig {
    associatedtype T: Scalar
    
    var value: T { get set }
    var range: ClosedRange<T> { get set }
}

extension ScalarConfig {
    
    func encode(into encoder: MTLComputeCommandEncoder) {
        var value = self.value
        encoder.setBytes(&value, length: MemoryLayout<T>.size, index: 0)
    }
}

struct FloatConfig: ScalarConfig {
    
    var value: Float
    var range: ClosedRange<Float>
    
    init(value: Float = 0.5,
         range: ClosedRange<Float> = 0.0...1.0) {
        self.value = value
        self.range = range
    }
}

struct UIntConfig: ScalarConfig {
    
    var value: UInt
    var range: ClosedRange<UInt>
    
    init(value: UInt = 5,
                  range: ClosedRange<UInt> = 0...10) {
        self.value = value
        self.range = range
    }
}
