//
//  ImageFilterPlan.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 23/5/26.
//

import Foundation
import Metal


protocol ImageFilterPlan {
    
    var passes: [PassDescriptor] { get }
    
    init(context: PlanContext) throws
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

struct PlanContext {
    let metalContext: MetalContext
    let kernels: [ComputeKernel]
    let inputTexture: MTLTexture
    let outputTexture: MTLTexture
    let config: ImageFilterConfig?
}

struct PassDescriptor {
    var pipelineState: MTLComputePipelineState
    var threadgroupsPerGrid: MTLSize
    var threadsPerThreadgroup: MTLSize
    var setArgs: (MTLComputeCommandEncoder) -> Void
}

enum PassPlanError: Error {
    case incorrectKernelCount
    case missingConfig
    case incorrectConfigType
    case failedToCreateTemporaryTexture
}
