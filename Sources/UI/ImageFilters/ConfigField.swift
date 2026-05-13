//
//  ConfigField.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 14/5/26.
//

import Metal

protocol Scalar: BitwiseCopyable, Comparable {}
extension Float: Scalar {}
extension UInt: Scalar {}

protocol MTLComputeEncodable {
    func encode(into encoder: MTLComputeCommandEncoder, index: Int)
}

final class ConfigField<T: Scalar>: MTLComputeEncodable {
    var name: String
    var value: T
    var range: ClosedRange<T>
    
    init(name: String, value: T, range: ClosedRange<T>) {
        self.name = name
        self.value = value
        self.range = range
    }
    
    func encode(into encoder: MTLComputeCommandEncoder, index: Int) {
        var value = value
        encoder.setBytes(&value, length: MemoryLayout<T>.size, index: index)
    }
}

extension ConfigField where T == Float {
    static func make(name: String, value: T, range: ClosedRange<T>) -> AnyConfigField {
        AnyConfigField(ConfigField<T>(name: name, value: value, range: range))
    }
}

extension ConfigField where T == UInt {
    static func make(name: String, value: T, range: ClosedRange<T>) -> AnyConfigField {
        AnyConfigField(ConfigField<T>(name: name, value: value, range: range))
    }
}

struct AnyConfigField: MTLComputeEncodable, Identifiable {
    var id: UUID = UUID()
    
    var name: String
    var encoderFunc: (MTLComputeCommandEncoder, Int) -> Void
    private var getValueFunc: () -> Float
    private var setValueFunc: (Float) -> Void
    private var getRangeFunc: () -> ClosedRange<Float>
    
    init(_ field: ConfigField<Float>) {
        self.name = field.name
        self.encoderFunc = { encoder, index in
            field.encode(into: encoder, index: index)
        }
        
        self.getValueFunc = {
            field.value
        }
        
        self.getRangeFunc = {
            field.range
        }
        
        self.setValueFunc = { newValue in
            field.value = newValue
        }
    }
    
    init(_ field: ConfigField<UInt>) {
        self.name = field.name
        self.encoderFunc = { encoder, index in
            field.encode(into: encoder, index: index)
        }
        
        self.getValueFunc = {
            Float(field.value)
        }
        
        self.getRangeFunc = {
            Float(field.range.lowerBound)...Float(field.range.upperBound)
        }
        
        self.setValueFunc = { newValue in
            field.value = UInt(newValue)
        }
    }
    
    func getValue() -> Float {
        getValueFunc()
    }
    
    func setValue(_ newValue: Float) {
        setValueFunc(newValue)
    }
    
    func getRange() -> ClosedRange<Float> {
        getRangeFunc()
    }
    
    func encode(into encoder: MTLComputeCommandEncoder, index: Int) {
        encoderFunc(encoder, index)
    }
}
