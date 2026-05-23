//
//  BoxBlurTwoPassPlan.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 23/5/26.
//

import Foundation
import Metal

struct BoxBlurTwoPassPlan: ImageFilterPlan {

    var passes: [PassDescriptor]
    
    init(context: PlanContext) throws {
        let kernels = context.kernels
        guard kernels.count == 2 else { throw PassPlanError.incorrectKernelCount }
        guard let config = context.config else { throw PassPlanError.missingConfig }
        
        let metalContext = context.metalContext
        let inputTexture = context.inputTexture
        
        let horizontalPSO = try metalContext.computePipelineState(for: kernels[0])
        let verticalPSO = try metalContext.computePipelineState(for: kernels[1])
        guard let tempTexture = inputTexture.makeEmptyCopy(device: metalContext.device) else { throw PassPlanError.failedToCreateTemporaryTexture }
        
        let threadgroupsPerGrid = MetalContext.threadgroupsPerGridForFullCoverage(inputTexture: inputTexture)
        
        self.passes = [
            
            PassDescriptor(pipelineState: horizontalPSO,
                           threadgroupsPerGrid: threadgroupsPerGrid,
                           threadsPerThreadgroup: MetalContext.defaultThreadsPerThreadgroup) { encoder in
                encoder.setTexture(inputTexture, index: 0)
                encoder.setTexture(tempTexture, index: 1)
                config.setBytes(to: encoder)
            },
            
            PassDescriptor(pipelineState: verticalPSO,
                           threadgroupsPerGrid: threadgroupsPerGrid,
                           threadsPerThreadgroup: MetalContext.defaultThreadsPerThreadgroup) { encoder in
                encoder.setTexture(tempTexture, index: 0)
                encoder.setTexture(context.outputTexture, index: 1)
                config.setBytes(to: encoder)
            }
        ]
    }
}

typealias GaussianBlurTwoPassPlan = BoxBlurTwoPassPlan
