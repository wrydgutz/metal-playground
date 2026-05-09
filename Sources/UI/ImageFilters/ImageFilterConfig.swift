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

final class FloatConfig: ImageFilterConfig {
    var value: Float = 0.5
    
    func encode(into encoder: inout MTLComputeCommandEncoder) {
        encoder.setBytes(&value, length: MemoryLayout<Float>.size, index: 0)
    }
}
