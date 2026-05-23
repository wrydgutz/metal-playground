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
    case boxBlurTwoPass
    case gaussianBlur
    case gaussianBlurTwoPass
    case sharpen
    case sobelEdgeDetection
    case emboss
    case bloom
    case unsharpMask
    
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
            case .boxBlurTwoPass: "Box Blur (Two-Pass)"
            case .gaussianBlur: "Gaussian Blur"
            case .gaussianBlurTwoPass: "Gaussian Blur (Two Pass)"
            case .sharpen: "Sharpen"
            case .sobelEdgeDetection: "Sobel Edge Detection"
            case .emboss: "Emboss"
            case .bloom: "Bloom"
            case .unsharpMask: "Unsharp Mask"
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
            case .boxBlurTwoPass: return [.boxBlurTwoPassHorizontal, .boxBlurTwoPassVertical]
            case .gaussianBlur: return [.gaussianBlur]
            case .gaussianBlurTwoPass: return [.gaussianBlurTwoPassHorizontal, .gaussianBlurTwoPassVertical]
            case .sharpen: return [.sharpen]
            case .sobelEdgeDetection: return [.sobelEdgeDetection]
            case .emboss: return [.emboss]
            case .bloom: return [.bloomBright, .gaussianBlurTwoPassHorizontal, .gaussianBlurTwoPassVertical, .bloomCombine]
            case .unsharpMask: return [.gaussianBlurTwoPassHorizontal, .gaussianBlurTwoPassVertical, .unsharpMask]
            default: return []
        }
    }

    func makePlan(metalContext: MetalContext,
                  inputTexture: MTLTexture,
                  outputTexture: MTLTexture,
                  config: ImageFilterConfig?) throws -> ImageFilterPlan? {
        
        let context = PlanContext(metalContext: metalContext,
                                  kernels: self.kernels,
                                  inputTexture: inputTexture,
                                  outputTexture: outputTexture,
                                  config: config)
        
        switch self {
            case .boxBlurTwoPass: return try BoxBlurTwoPassPlan(context: context)
            case .gaussianBlurTwoPass: return try GaussianBlurTwoPassPlan(context: context)
            case .bloom: return try BloomPlan(context: context)
            case .unsharpMask: return try UnsharpMaskPlan(context: context)
            default: return try SinglePassPlan(context: context)
        }
    }
}
