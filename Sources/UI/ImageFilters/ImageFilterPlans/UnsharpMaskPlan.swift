//
//  UnsharpMaskPlan.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 23/5/26.
//

import Foundation
import Metal

struct UnsharpMaskPlan: ImageFilterPlan {

    var passes: [PassDescriptor]
    
    init(context: PlanContext) throws {
        let kernels = context.kernels
        guard context.kernels.count == ImageFilter.unsharpMask.kernels.count else { throw PassPlanError.incorrectKernelCount }
        guard let config = context.config else { throw PassPlanError.missingConfig }
        guard let unsharpMaskConfig = config as? UnsharpMaskConfig else { throw PassPlanError.incorrectConfigType }
        
        let metalContext = context.metalContext
        let inputTexture = context.inputTexture
        
        let gaussianBlurHorizontalPSO = try metalContext.computePipelineState(for: kernels[0])
        let gaussianBlurVerticalPSO = try metalContext.computePipelineState(for: kernels[1])
        let combinePSO = try metalContext.computePipelineState(for: kernels[2])
        
        guard let gaussianBlurHorizontalOutputTexture = inputTexture.makeEmptyCopy(device: metalContext.device)
        else { throw PassPlanError.failedToCreateTemporaryTexture }
        
        guard let gaussianBlurVerticalOutputTexture = inputTexture.makeEmptyCopy(device: metalContext.device)
        else { throw PassPlanError.failedToCreateTemporaryTexture }
        
        let threadgroupsPerGrid = MetalContext.threadgroupsPerGridForFullCoverage(inputTexture: inputTexture)
        
        var blurSigma: Float = unsharpMaskConfig.radius.getValue() / 3
        
        self.passes = [
            
            // Gaussian Blur Passes
            PassDescriptor(pipelineState: gaussianBlurHorizontalPSO,
                           threadgroupsPerGrid: threadgroupsPerGrid,
                           threadsPerThreadgroup: MetalContext.defaultThreadsPerThreadgroup) { encoder in
                encoder.setTexture(inputTexture, index: 0)
                encoder.setTexture(gaussianBlurHorizontalOutputTexture, index: 1)
                unsharpMaskConfig.radius.encode(into: encoder, index: 0)
                encoder.setBytes(&blurSigma, length: MemoryLayout<Float>.size, index: 1)
            },
            
            PassDescriptor(pipelineState: gaussianBlurVerticalPSO,
                           threadgroupsPerGrid: threadgroupsPerGrid,
                           threadsPerThreadgroup: MetalContext.defaultThreadsPerThreadgroup) { encoder in
                encoder.setTexture(gaussianBlurHorizontalOutputTexture, index: 0)
                encoder.setTexture(gaussianBlurVerticalOutputTexture, index: 1)
                unsharpMaskConfig.radius.encode(into: encoder, index: 0)
                encoder.setBytes(&blurSigma, length: MemoryLayout<Float>.size, index: 1)
            },
            
            // Combine Pass
            PassDescriptor(pipelineState: combinePSO,
                           threadgroupsPerGrid: threadgroupsPerGrid,
                           threadsPerThreadgroup: MetalContext.defaultThreadsPerThreadgroup) { encoder in
                encoder.setTexture(inputTexture, index: 0)
                encoder.setTexture(gaussianBlurVerticalOutputTexture, index: 1)
                encoder.setTexture(context.outputTexture, index: 2)
                unsharpMaskConfig.amount.encode(into: encoder, index: 0)
            }
        ]
    }
}
