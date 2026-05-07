//
//  ImageFiltersViewModel.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 5/5/26.
//

import UIKit
import Observation
import Metal
import MetalKit

enum ImageFilter: CaseIterable, Identifiable {
    case original
    case grayscale
    
    var id: Self { self }
    var title: String {
        switch self {
            case .original: "Original"
            case .grayscale: "Grayscale"
        }
    }
    
    func pipelineStateObject(metalContext: MetalContext) throws -> MTLComputePipelineState? {
        switch self {
            case .grayscale: return try metalContext.pipelineStateObjects.grayscale()
            default: return nil
        }
    }
}

@Observable
final class ImageFiltersViewModel {
    
    var filter = ImageFilter.original
    var isProcessed = false
    var textureMapping = TextureMapping.identity
    
    @ObservationIgnored var filters = [ImageFilter:MTLTexture]()
    @ObservationIgnored var metalContext = MetalContext()
    
    func process(image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        isProcessed = false
        filter = .original
        textureMapping = image.imageOrientation.textureMapping
        
        let loader = MTKTextureLoader(device: metalContext.device)
        
        do {
            let texture = try loader.newTexture(cgImage: cgImage)
            loadFilterTextures(original: texture)
            try processFilters()
        } catch {
            print("Error: \(error.localizedDescription)")
        }
        
        isProcessed = true
    }
    
    func loadFilterTextures(original: MTLTexture) {
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: original.width,
            height: original.height,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead, .shaderWrite]
        descriptor.storageMode = .shared
        
        filters[.original] = original
        
        for name in ImageFilter.allCases {
            if name == .original { continue }
            filters[name] = metalContext.device.makeTexture(descriptor: descriptor)
        }
    }
    
    func processFilters() throws {
        for name in ImageFilter.allCases {
            if name == .original { continue }
            guard let pipelineStateObject = try name.pipelineStateObject(metalContext: metalContext) else { continue }
            process(filter: .grayscale, pipelineState: pipelineStateObject)
        }
    }
    
    func process(filter: ImageFilter, pipelineState: MTLComputePipelineState) {
        
        guard filter != .original else { return }
        guard !filters.isEmpty else { return }
        guard let inputTexture = filters[.original] else { return }
        guard let outputTexture = filters[filter] else { return }
        guard let commandBuffer = metalContext.commandQueue.makeCommandBuffer() else { return }
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        computeEncoder.setComputePipelineState(pipelineState)
        computeEncoder.setTexture(inputTexture, index: 0)
        computeEncoder.setTexture(outputTexture, index: 1)
        
        let threadgroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadgroupCount = MTLSize(
            width: (inputTexture.width + threadgroupSize.width - 1) / threadgroupSize.width,
            height: (inputTexture.height + threadgroupSize.height - 1) / threadgroupSize.height,
            depth: 1
        )
        
        computeEncoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadgroupSize)
        
        computeEncoder.endEncoding()
        commandBuffer.commit()
        
        commandBuffer.waitUntilCompleted()
    }
}
