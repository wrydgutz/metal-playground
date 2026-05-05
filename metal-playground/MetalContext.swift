//
//  MetalContext.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 5/5/26.
//

import Metal

final class MetalContext {
    
    let device: MTLDevice
    let library: MTLLibrary
    let commandQueue: MTLCommandQueue
    
    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to create default library")
        }

        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Failed to create command queue")
        }
        
        self.device = device
        self.library = library
        self.commandQueue = commandQueue
    }
}
