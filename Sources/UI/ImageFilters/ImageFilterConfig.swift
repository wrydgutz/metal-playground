//
//  ImageFilterConfig.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 9/5/26.
//

import Metal


protocol ImageFilterConfig {
    
    var fields: [AnyConfigField] { get }
}

extension ImageFilterConfig {
    
    func setBytes(to encoder: MTLComputeCommandEncoder) {
        for i in 0..<fields.count {
            fields[i].setBytes(to: encoder, index: i)
        }
    }
}


struct SingleFieldConfig: ImageFilterConfig {
    
    var fields: [AnyConfigField]
    
    var field: AnyConfigField { fields[0] }
    
    init(name: String, value: Float, range: ClosedRange<Float>) {
        self.fields = [
            ConfigField.make(name: name, value: value, range: range)
        ]
    }
    
    init(name: String, value: UInt, range: ClosedRange<UInt>) {
        self.fields = [
            ConfigField.make(name: name, value: value, range: range)
        ]
    }
}

struct GaussianBlurConfig: ImageFilterConfig {
    
    var fields: [AnyConfigField]
    
    var radius: AnyConfigField { fields[0] }
    var sigma: AnyConfigField { fields[1] }
    
    init() {
        self.fields = [
            ConfigField<UInt>.make(name: "Radius", value: 10, range: 0...20),
            ConfigField<Float>.make(name: "Strength", value: 5.0, range: 0...30.0)
        ]
    }
}

struct BloomConfig: ImageFilterConfig {
    
    var fields: [AnyConfigField]
    
    var threshold: AnyConfigField { fields[0] }
    var radius: AnyConfigField { fields[1] }
    var intensity: AnyConfigField { fields[2] }
    
    init() {
        self.fields = [
            ConfigField<Float>.make(name: "Threshold", value: 0.5, range: 0.0...1.0),
            ConfigField<UInt>.make(name: "Radius", value: 10, range: 0...30),
            ConfigField<Float>.make(name: "Intensity", value: 0.5, range: 0.0...1.0)
        ]
    }
}

struct UnsharpMaskConfig: ImageFilterConfig {
    
    var fields: [AnyConfigField]
    
    var radius: AnyConfigField { fields[0] }
    var amount: AnyConfigField { fields[1] }
    
    init() {
        self.fields = [
            ConfigField<UInt>.make(name: "Radius", value: 10, range: 0...30),
            ConfigField<Float>.make(name: "Amount", value: 0.5, range: 0.0...2.0)
        ]
    }
}
