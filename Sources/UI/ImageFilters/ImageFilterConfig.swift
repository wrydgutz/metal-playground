//
//  ImageFilterConfig.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 9/5/26.
//

import Metal


struct ImageFilterConfig {
    
    var fields: [AnyConfigField]
    
    func encode(into encoder: MTLComputeCommandEncoder) {
        for i in 0..<fields.count {
            fields[i].encode(into: encoder, index: i)
        }
    }
}
