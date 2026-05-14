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
            default: return []
        }
    }

    func makePlan(metalContext: MetalContext,
                  inputTexture: MTLTexture,
                  outputTexture: MTLTexture,
                  encodeCommands: ((MTLComputeCommandEncoder) -> Void)?
    ) throws -> ImageFilterPlan? {
        switch self {
            case .boxBlurTwoPass:
                return try BoxBlurTwoPassPlan(metalContext: metalContext,
                                              kernels: kernels,
                                              inputTexture: inputTexture,
                                              outputTexture: outputTexture,
                                              encodeCommands: encodeCommands)
                
            case .gaussianBlurTwoPass:
                return try GaussianBlurTwoPassPlan(metalContext: metalContext,
                                                   kernels: kernels,
                                                   inputTexture: inputTexture,
                                                   outputTexture: outputTexture,
                                                   encodeCommands: encodeCommands)
                
            default:
                return try SinglePassPlan(metalContext: metalContext,
                                          kernels: kernels,
                                          inputTexture: inputTexture,
                                          outputTexture: outputTexture,
                                          encodeCommands: encodeCommands)
        }
    }
}

protocol ImageFilterPlan {
    
    var passes: [ImageFilter.PassDescriptor] { get }
    
    func encode(to commandBuffer: MTLCommandBuffer)
}

extension ImageFilterPlan {
    
    func encode(to commandBuffer: MTLCommandBuffer) {
        for pass in passes {
            MetalContext.encodeComputePass(pipelineState: pass.pipelineState,
                                           commandBuffer: commandBuffer,
                                           inputTexture: pass.inputTexture,
                                           outputTexture: pass.outputTexture,
                                           encodeCommands: pass.encodeCommands)
        }
    }
}

extension ImageFilter {
    
    struct PassDescriptor {
        var pipelineState: MTLComputePipelineState
        var inputTexture: MTLTexture
        var outputTexture: MTLTexture
        var encodeCommands: ((MTLComputeCommandEncoder) -> Void)?
    }
    
    enum SinglePassPlanError: Error {
        case moreThanOneKernel
        case noKernel
    }

    final class SinglePassPlan: ImageFilterPlan {
    
        var passes: [ImageFilter.PassDescriptor]
        
        init(metalContext: MetalContext,
             kernels: [ComputeKernel],
             inputTexture: MTLTexture,
             outputTexture: MTLTexture,
             encodeCommands: ((MTLComputeCommandEncoder) -> Void)?
        ) throws {
            guard kernels.count == 1 else { throw SinglePassPlanError.moreThanOneKernel }
            guard let kernel = kernels.first else { throw SinglePassPlanError.noKernel }
            
            let pso = try metalContext.computePipelineState(for: kernel)
            
            let pass = PassDescriptor(pipelineState: pso,
                                      inputTexture: inputTexture,
                                      outputTexture: outputTexture,
                                      encodeCommands: encodeCommands)
            self.passes = [pass]
        }
    }
    
    enum BoxBlurTwoPassPlanError: Error {
        case incorrectKernelCount
        case failedToCreateTemporaryTexture
    }

    struct BoxBlurTwoPassPlan: ImageFilterPlan {
    
        var passes: [ImageFilter.PassDescriptor]
        
        init(metalContext: MetalContext,
             kernels: [ComputeKernel],
             inputTexture: MTLTexture,
             outputTexture: MTLTexture,
             encodeCommands: ((MTLComputeCommandEncoder) -> Void)?
        ) throws {
            guard kernels.count == 2 else { throw BoxBlurTwoPassPlanError.incorrectKernelCount }
            
            let horizontalPSO = try metalContext.computePipelineState(for: kernels[0])
            let verticalPSO = try metalContext.computePipelineState(for: kernels[1])
            guard let tempTexture = inputTexture.makeEmptyCopy(device: metalContext.device) else { throw BoxBlurTwoPassPlanError.failedToCreateTemporaryTexture }
            
            self.passes = [
                PassDescriptor(pipelineState: horizontalPSO,
                               inputTexture: inputTexture,
                               outputTexture: tempTexture,
                               encodeCommands: encodeCommands),
                
                PassDescriptor(pipelineState: verticalPSO,
                               inputTexture: tempTexture,
                               outputTexture: outputTexture,
                               encodeCommands: encodeCommands)
            ]
        }
    }
    
    typealias GaussianBlurTwoPassPlan = BoxBlurTwoPassPlan
}
