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

@Observable
final class ImageFiltersViewModel {
    
    var filter: ImageFilter = .original
    var displayTexture: MTLTexture?
    var displayTextureRedrawID: Int = 0
    var isProcessed = false
    var textureMapping = TextureMapping.identity
    
    @ObservationIgnored var filtersWithFloatConfigs: [ImageFilter] = [ .brightness, .contrast, .threshold ]
    @ObservationIgnored var filtersWithUIntConfigs: [ImageFilter] = [ .boxBlur ]
    
    @ObservationIgnored var filters = [ImageFilter:MTLTexture]()
    @ObservationIgnored var filterConfigs = [ImageFilter:ImageFilterConfig]()
    @ObservationIgnored var metalContext = MetalContext()
    
    init() {
        for filter in filtersWithFloatConfigs {
            filterConfigs[filter] = FloatConfig()
        }
        
        for filter in filtersWithUIntConfigs {
            if filter == .boxBlur {
                filterConfigs[filter] = UIntConfig(value: 10, range: 0...20)
            } else {
                filterConfigs[filter] = UIntConfig()
            }
        }
    }
    
    func select(filter: ImageFilter) {
        self.filter = filter
        displayTexture = filters[filter]
    }
    
    func process(image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        isProcessed = false
        filter = .original
        textureMapping = image.imageOrientation.textureMapping
        
        let loader = MTKTextureLoader(device: metalContext.device)
        
        do {
            let texture = try loader.newTexture(cgImage: cgImage)
            displayTexture = texture
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
        
        filters[.original] = original.makeCopy(device: metalContext.device,
                                               queue: metalContext.commandQueue)
        
        for name in ImageFilter.allCases {
            if name == .original { continue }
            filters[name] = metalContext.device.makeTexture(descriptor: descriptor)
        }
    }
    
    func processFilters() throws {
        for name in ImageFilter.allCases {
            if name == .original { continue }
            guard let pipelineStateObject = try name.pipelineStateObject(metalContext: metalContext) else { continue }
            guard let outputTexture = filters[name] else { return }
            process(filter: name, pipelineState: pipelineStateObject, outputTexture: outputTexture) { computeEncoder in
                guard let config = filterConfigs[name] else { return }
                config.encode(into: &computeEncoder)
            }
        }
    }
    
    func process(filter: ImageFilter, pipelineState: MTLComputePipelineState, outputTexture: MTLTexture, computeEncoderArgs: (inout MTLComputeCommandEncoder) -> Void) {
        
        guard filter != .original else { return }
        guard !filters.isEmpty else { return }
        guard let inputTexture = filters[.original] else { return }
        guard let commandBuffer = metalContext.commandQueue.makeCommandBuffer() else { return }
        guard var computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        computeEncoder.setComputePipelineState(pipelineState)
        computeEncoder.setTexture(inputTexture, index: 0)
        computeEncoder.setTexture(outputTexture, index: 1)
        computeEncoderArgs(&computeEncoder)
        
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
    
    func process(filter: ImageFilter, updateConfig: (ImageFilterConfig) -> Void) throws {
        
        guard let config = filterConfigs[filter] else { return }
        guard let pipelineStateObject = try filter.pipelineStateObject(metalContext: metalContext) else { return }
        guard let outputTexture = displayTexture else { return }
        
        updateConfig(config)
        
        process(filter: filter, pipelineState: pipelineStateObject, outputTexture: outputTexture) { computeEncoder in
            config.encode(into: &computeEncoder)
        }
        
        displayTextureRedrawID += 1
    }
}
