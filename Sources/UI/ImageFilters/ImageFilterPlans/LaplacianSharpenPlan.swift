//
//  LaplacianSharpenPlan.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 24/5/26.
//

import Foundation
import Metal

struct LaplacianSharpenPlan: ImageFilterPlan {

    var passes: [PassDescriptor]
    
    init(context: PlanContext) throws {
        let kernels = context.kernels
        guard context.kernels.count == ImageFilter.laplacianSharpen.kernels.count else { throw PassPlanError.incorrectKernelCount }
        guard let config = context.config else { throw PassPlanError.missingConfig }
        guard let laplacianSharpenConfig = config as? LaplacianSharpenConfig else { throw PassPlanError.incorrectConfigType }
        
        let metalContext = context.metalContext
        let inputTexture = context.inputTexture
        
        let gaussianBlurHorizontalPSO = try metalContext.computePipelineState(for: kernels[0])
        let gaussianBlurVerticalPSO = try metalContext.computePipelineState(for: kernels[1])
        let laplacianPSO = try metalContext.computePipelineState(for: kernels[2])
        let combinePSO = try metalContext.computePipelineState(for: kernels[3])
        
        guard let gaussianBlurHorizontalOutputTexture = inputTexture.makeEmptyCopy(device: metalContext.device)
        else { throw PassPlanError.failedToCreateTemporaryTexture }
        
        guard let gaussianBlurVerticalOutputTexture = inputTexture.makeEmptyCopy(device: metalContext.device)
        else { throw PassPlanError.failedToCreateTemporaryTexture }
        
        guard let laplacianOutputTexture = inputTexture.makeEmptyCopy(device: metalContext.device)
        else { throw PassPlanError.failedToCreateTemporaryTexture }
        
        let threadgroupsPerGrid = MetalContext.threadgroupsPerGridForFullCoverage(inputTexture: inputTexture)
        
        var blurSigma: Float = laplacianSharpenConfig.radius.getValue() / 3
        
        self.passes = [
            
            // Gaussian Blur Passes
            PassDescriptor(pipelineState: gaussianBlurHorizontalPSO,
                           threadgroupsPerGrid: threadgroupsPerGrid,
                           threadsPerThreadgroup: MetalContext.defaultThreadsPerThreadgroup) { encoder in
                encoder.setTexture(inputTexture, index: 0)
                encoder.setTexture(gaussianBlurHorizontalOutputTexture, index: 1)
                laplacianSharpenConfig.radius.setBytes(to: encoder, index: 0)
                encoder.setBytes(&blurSigma, length: MemoryLayout<Float>.size, index: 1)
            },
            
            PassDescriptor(pipelineState: gaussianBlurVerticalPSO,
                           threadgroupsPerGrid: threadgroupsPerGrid,
                           threadsPerThreadgroup: MetalContext.defaultThreadsPerThreadgroup) { encoder in
                encoder.setTexture(gaussianBlurHorizontalOutputTexture, index: 0)
                encoder.setTexture(gaussianBlurVerticalOutputTexture, index: 1)
                laplacianSharpenConfig.radius.setBytes(to: encoder, index: 0)
                encoder.setBytes(&blurSigma, length: MemoryLayout<Float>.size, index: 1)
            },
            
            // Laplacian Pass
            PassDescriptor(pipelineState: laplacianPSO,
                           threadgroupsPerGrid: threadgroupsPerGrid,
                           threadsPerThreadgroup: MetalContext.defaultThreadsPerThreadgroup) { encoder in
                encoder.setTexture(gaussianBlurVerticalOutputTexture, index: 0)
                encoder.setTexture(laplacianOutputTexture, index: 1)
                laplacianSharpenConfig.gain.setBytes(to: encoder, index: 0)
            },
            
            // Combine Pass
            PassDescriptor(pipelineState: combinePSO,
                           threadgroupsPerGrid: threadgroupsPerGrid,
                           threadsPerThreadgroup: MetalContext.defaultThreadsPerThreadgroup) { encoder in
                encoder.setTexture(inputTexture, index: 0)
                encoder.setTexture(laplacianOutputTexture, index: 1)
                encoder.setTexture(context.outputTexture, index: 2)
                laplacianSharpenConfig.amount.setBytes(to: encoder, index: 0)
            }
        ]
    }
}
