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
            case .grayscale: return try metalContext.computePipelineState(for: .grayscale)
            case .sepia: return try metalContext.computePipelineState(for: .sepia)
            case .invert: return try metalContext.computePipelineState(for: .invert)
            case .brightness: return try metalContext.computePipelineState(for: .brightness)
            case .contrast: return try metalContext.computePipelineState(for: .contrast)
            case .threshold: return try metalContext.computePipelineState(for: .threshold)
            case .boxBlur: return try metalContext.computePipelineState(for: .boxBlur)
            default: return nil
        }
    }
}
