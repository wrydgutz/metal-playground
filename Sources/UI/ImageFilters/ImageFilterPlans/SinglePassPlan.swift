//
//  SinglePassPlan.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 23/5/26.
//

import Foundation
import Metal

final class SinglePassPlan: ImageFilterPlan {

    var passes: [PassDescriptor]
    
    init(context: PlanContext) throws {
        guard context.kernels.count == 1 else { throw PassPlanError.incorrectKernelCount }
        
        let kernel = context.kernels[0]
        let pso = try context.metalContext.computePipelineState(for: kernel)
        
        self.passes = [
            PassDescriptor(pipelineState: pso,
                           threadgroupsPerGrid: MetalContext.threadgroupsPerGridForFullCoverage(inputTexture: context.inputTexture),
                           threadsPerThreadgroup: MetalContext.defaultThreadsPerThreadgroup) { encoder in
            encoder.setTexture(context.inputTexture, index: 0)
            encoder.setTexture(context.outputTexture, index: 1)
            context.config?.encode(into: encoder)
        }]
    }
}
