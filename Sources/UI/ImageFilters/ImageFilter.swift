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

struct PlanContext {
    let metalContext: MetalContext
    let kernels: [ComputeKernel]
    let inputTexture: MTLTexture
    let outputTexture: MTLTexture
    let config: ImageFilterConfig?
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
                                           threadgroupsPerGrid: pass.threadgroupsPerGrid,
                                           threadsPerThreadgroup: pass.threadsPerThreadgroup,
                                           setArgs: pass.setArgs)
        }
    }
}

extension ImageFilter {
    
    struct PassDescriptor {
        var pipelineState: MTLComputePipelineState
        var threadgroupsPerGrid: MTLSize
        var threadsPerThreadgroup: MTLSize
        var setArgs: (MTLComputeCommandEncoder) -> Void
    }
    
    enum SinglePassPlanError: Error {
        case moreThanOneKernel
        case noKernel
    }

    final class SinglePassPlan: ImageFilterPlan {
    
        var passes: [ImageFilter.PassDescriptor]
        
        init(context: PlanContext) throws {
            guard context.kernels.count == 1 else { throw SinglePassPlanError.moreThanOneKernel }
            guard let kernel = context.kernels.first else { throw SinglePassPlanError.noKernel }
            
            let pso = try context.metalContext.computePipelineState(for: kernel)
            
            let pass = PassDescriptor(pipelineState: pso,
                                      threadgroupsPerGrid: MetalContext.threadgroupsPerGridForFullCoverage(inputTexture: context.inputTexture),
                                      threadsPerThreadgroup: MetalContext.defaultThreadsPerThreadgroup) { encoder in
                encoder.setTexture(context.inputTexture, index: 0)
                encoder.setTexture(context.outputTexture, index: 1)
                context.config?.encode(into: encoder)
            }
            self.passes = [pass]
        }
    }
    
    enum BoxBlurTwoPassPlanError: Error {
        case incorrectKernelCount
        case missingConfig
        case failedToCreateTemporaryTexture
    }

    struct BoxBlurTwoPassPlan: ImageFilterPlan {
    
        var passes: [ImageFilter.PassDescriptor]
        
        init(context: PlanContext) throws {
            guard context.kernels.count == 2 else { throw BoxBlurTwoPassPlanError.incorrectKernelCount }
            guard let config = context.config else { throw BloomPlanError.missingConfig }
            
            let metalContext = context.metalContext
            let inputTexture = context.inputTexture
            
            let horizontalPSO = try metalContext.computePipelineState(for: context.kernels[0])
            let verticalPSO = try metalContext.computePipelineState(for: context.kernels[1])
            guard let tempTexture = inputTexture.makeEmptyCopy(device: metalContext.device) else { throw BoxBlurTwoPassPlanError.failedToCreateTemporaryTexture }
            
            let threadgroupsPerGrid = MetalContext.threadgroupsPerGridForFullCoverage(inputTexture: inputTexture)
            
            self.passes = [
                
                PassDescriptor(pipelineState: horizontalPSO,
                               threadgroupsPerGrid: threadgroupsPerGrid,
                               threadsPerThreadgroup: MetalContext.defaultThreadsPerThreadgroup) { encoder in
                    encoder.setTexture(inputTexture, index: 0)
                    encoder.setTexture(tempTexture, index: 1)
                    config.encode(into: encoder)
                },
                
                PassDescriptor(pipelineState: verticalPSO,
                               threadgroupsPerGrid: threadgroupsPerGrid,
                               threadsPerThreadgroup: MetalContext.defaultThreadsPerThreadgroup) { encoder in
                    encoder.setTexture(tempTexture, index: 0)
                    encoder.setTexture(context.outputTexture, index: 1)
                    config.encode(into: encoder)
                }
            ]
        }
    }
    
    typealias GaussianBlurTwoPassPlan = BoxBlurTwoPassPlan
    
    enum BloomPlanError: Error {
        case incorrectKernelCount
        case missingConfig
        case failedToCreateTemporaryTexture
    }

    struct BloomPlan: ImageFilterPlan {
    
        var passes: [ImageFilter.PassDescriptor]
        
        init(context: PlanContext) throws {
            let kernels = context.kernels
            guard kernels.count == ImageFilter.bloom.kernels.count else { throw BloomPlanError.incorrectKernelCount }
            guard let config = context.config else { throw BloomPlanError.missingConfig }
            
            let metalContext = context.metalContext
            let inputTexture = context.inputTexture
            
            let brightPSO = try metalContext.computePipelineState(for: kernels[0])
            let gaussianBlurHorizontalPSO = try metalContext.computePipelineState(for: kernels[1])
            let gaussianBlurVerticalPSO = try metalContext.computePipelineState(for: kernels[2])
            let combinePSO = try metalContext.computePipelineState(for: kernels[3])
            
            guard let brightOutputTexture = inputTexture.makeEmptyCopy(device: metalContext.device) else { throw BloomPlanError.failedToCreateTemporaryTexture }
            guard let gaussianBlurHorizontalOutputTexture = inputTexture.makeEmptyCopy(device: metalContext.device) else { throw BloomPlanError.failedToCreateTemporaryTexture }
            guard let gaussianBlurVerticalOutputTexture = inputTexture.makeEmptyCopy(device: metalContext.device) else { throw BloomPlanError.failedToCreateTemporaryTexture }
            
            let threadgroupsPerGrid = MetalContext.threadgroupsPerGridForFullCoverage(inputTexture: inputTexture)
            
            var blurSigma: Float = config.fields[1].getValue() / 3
            
            self.passes = [
                
                // Bright Pass
                PassDescriptor(pipelineState: brightPSO,
                               threadgroupsPerGrid: threadgroupsPerGrid,
                               threadsPerThreadgroup: MetalContext.defaultThreadsPerThreadgroup) { encoder in
                    encoder.setTexture(inputTexture, index: 0)
                    encoder.setTexture(brightOutputTexture, index: 1)
                    config.fields[0].encode(into: encoder, index: 0) // Threshold
                },
                
                // Gaussian Blur Passes
                PassDescriptor(pipelineState: gaussianBlurHorizontalPSO,
                               threadgroupsPerGrid: threadgroupsPerGrid,
                               threadsPerThreadgroup: MetalContext.defaultThreadsPerThreadgroup) { encoder in
                    encoder.setTexture(brightOutputTexture, index: 0)
                    encoder.setTexture(gaussianBlurHorizontalOutputTexture, index: 1)
                    config.fields[1].encode(into: encoder, index: 0) // Radius
                    encoder.setBytes(&blurSigma, length: MemoryLayout<Float>.size, index: 1)  // Sigma
                },
                
                PassDescriptor(pipelineState: gaussianBlurVerticalPSO,
                               threadgroupsPerGrid: threadgroupsPerGrid,
                               threadsPerThreadgroup: MetalContext.defaultThreadsPerThreadgroup) { encoder in
                    encoder.setTexture(gaussianBlurHorizontalOutputTexture, index: 0)
                    encoder.setTexture(gaussianBlurVerticalOutputTexture, index: 1)
                    config.fields[1].encode(into: encoder, index: 0) // Radius
                    encoder.setBytes(&blurSigma, length: MemoryLayout<Float>.size, index: 1)  // Sigma
                },
                
                // Combine Pass
                PassDescriptor(pipelineState: combinePSO,
                               threadgroupsPerGrid: threadgroupsPerGrid,
                               threadsPerThreadgroup: MetalContext.defaultThreadsPerThreadgroup) { encoder in
                    encoder.setTexture(inputTexture, index: 0)
                    encoder.setTexture(gaussianBlurVerticalOutputTexture, index: 1)
                    encoder.setTexture(context.outputTexture, index: 2)
                    config.fields[2].encode(into: encoder, index: 0) // Intensity
                }
            ]
        }
    }
    
    enum UnsharpMaskPlanError: Error {
        case incorrectKernelCount
        case missingConfig
        case failedToCreateTemporaryTexture
    }

    struct UnsharpMaskPlan: ImageFilterPlan {
    
        var passes: [ImageFilter.PassDescriptor]
        
        init(context: PlanContext) throws {
            let kernels = context.kernels
            guard context.kernels.count == ImageFilter.unsharpMask.kernels.count else { throw UnsharpMaskPlanError.incorrectKernelCount }
            guard let config = context.config else { throw BloomPlanError.missingConfig }
            
            let metalContext = context.metalContext
            let inputTexture = context.inputTexture
            
            let gaussianBlurHorizontalPSO = try metalContext.computePipelineState(for: kernels[0])
            let gaussianBlurVerticalPSO = try metalContext.computePipelineState(for: kernels[1])
            let combinePSO = try metalContext.computePipelineState(for: kernels[2])
            
            guard let gaussianBlurHorizontalOutputTexture = inputTexture.makeEmptyCopy(device: metalContext.device) else { throw UnsharpMaskPlanError.failedToCreateTemporaryTexture }
            guard let gaussianBlurVerticalOutputTexture = inputTexture.makeEmptyCopy(device: metalContext.device) else { throw UnsharpMaskPlanError.failedToCreateTemporaryTexture }
            
            let threadgroupsPerGrid = MetalContext.threadgroupsPerGridForFullCoverage(inputTexture: inputTexture)
            
            var blurSigma: Float = config.fields[0].getValue() / 3
            
            self.passes = [
                
                // Gaussian Blur Passes
                PassDescriptor(pipelineState: gaussianBlurHorizontalPSO,
                               threadgroupsPerGrid: threadgroupsPerGrid,
                               threadsPerThreadgroup: MetalContext.defaultThreadsPerThreadgroup) { encoder in
                    encoder.setTexture(inputTexture, index: 0)
                    encoder.setTexture(gaussianBlurHorizontalOutputTexture, index: 1)
                    config.fields[0].encode(into: encoder, index: 0) // Radius
                    encoder.setBytes(&blurSigma, length: MemoryLayout<Float>.size, index: 1)  // Sigma
                },
                
                PassDescriptor(pipelineState: gaussianBlurVerticalPSO,
                               threadgroupsPerGrid: threadgroupsPerGrid,
                               threadsPerThreadgroup: MetalContext.defaultThreadsPerThreadgroup) { encoder in
                    encoder.setTexture(gaussianBlurHorizontalOutputTexture, index: 0)
                    encoder.setTexture(gaussianBlurVerticalOutputTexture, index: 1)
                    config.fields[0].encode(into: encoder, index: 0) // Radius
                    encoder.setBytes(&blurSigma, length: MemoryLayout<Float>.size, index: 1)  // Sigma
                },
                
                // Combine Pass
                PassDescriptor(pipelineState: combinePSO,
                               threadgroupsPerGrid: threadgroupsPerGrid,
                               threadsPerThreadgroup: MetalContext.defaultThreadsPerThreadgroup) { encoder in
                    encoder.setTexture(inputTexture, index: 0)
                    encoder.setTexture(gaussianBlurVerticalOutputTexture, index: 1)
                    encoder.setTexture(context.outputTexture, index: 2)
                    config.fields[1].encode(into: encoder, index: 0) // Amount
                }
            ]
        }
    }
}
