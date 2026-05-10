//
//  ImageFilter.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 9/5/26.
//

import Metal

enum ImageFilter: CaseIterable, Identifiable {
    case original
    case grayscale
    case sepia
    case invert
    case brightness
    case contrast
    case threshold
    case boxBlur
    
    var id: Self { self }
    var title: String {
        switch self {
            case .original: "Original"
            case .grayscale: "Grayscale"
            case .sepia: "Sepia"
            case .invert: "Invert"
            case .brightness: "Brightness"
            case .contrast: "Contrast"
            case .threshold: "Threshold"
            case .boxBlur: "Box Blur"
        }
    }
    
    func pipelineStateObject(metalContext: MetalContext) throws -> MTLComputePipelineState? {
        switch self {
            case .grayscale: return try metalContext.pipelineStateObjects.grayscale()
            case .sepia: return try metalContext.pipelineStateObjects.sepia()
            case .invert: return try metalContext.pipelineStateObjects.invert()
            case .brightness: return try metalContext.pipelineStateObjects.brightness()
            case .contrast: return try metalContext.pipelineStateObjects.contrast()
            case .threshold: return try metalContext.pipelineStateObjects.threshold()
            case .boxBlur: return try metalContext.pipelineStateObjects.boxBlur()
            default: return nil
        }
    }
}
