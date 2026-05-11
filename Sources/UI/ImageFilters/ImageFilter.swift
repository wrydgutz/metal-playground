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
    
    var kernels: [ComputeKernel] {
        switch self {
            case .grayscale: return [.grayscale]
            case .sepia: return [.sepia]
            case .invert: return [.invert]
            case .brightness: return [.brightness]
            case .contrast: return [.contrast]
            case .threshold: return [.threshold]
            case .boxBlur: return [.boxBlur]
            default: return []
        }
    }
}
