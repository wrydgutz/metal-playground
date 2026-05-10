//
//  ImageFilterConfig.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 9/5/26.
//

import Metal

protocol ImageFilterConfig {
    func encode(into encoder: inout MTLComputeCommandEncoder)
}

protocol Scalar: BitwiseCopyable, Comparable {}
extension Float: Scalar {}
extension UInt: Scalar {}

class ScalarConfig<T>: ImageFilterConfig
where T: Scalar {
    var value: T
    var range: ClosedRange<T>
    
    init(value: T,
         range: ClosedRange<T>) {
        self.value = value
        self.range = range
    }
    
    func encode(into encoder: inout MTLComputeCommandEncoder) {
        var value = self.value
        encoder.setBytes(&value, length: MemoryLayout<T>.size, index: 0)
    }
}

final class FloatConfig: ScalarConfig<Float> {
    
    override init(value: Float = 0.5,
                  range: ClosedRange<Float> = 0.0...1.0) {
        super.init(value: value, range: range)
    }
}

final class UIntConfig: ScalarConfig<UInt> {
    
    override init(value: UInt = 5,
                  range: ClosedRange<UInt> = 0...10) {
        super.init(value: value, range: range)
    }
}
