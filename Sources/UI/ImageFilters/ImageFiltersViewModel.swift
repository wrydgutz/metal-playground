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
    
    @ObservationIgnored var filters = [ImageFilter:(preview: MTLTexture?, reprocessBuffer:MTLTexture?)]()
    @ObservationIgnored var filterConfigs = [ImageFilter:ImageFilterConfig]()
    @ObservationIgnored var metalContext = MetalContext()
    
    @ObservationIgnored private var reprocessInProgress = false
    @ObservationIgnored private var pendingConfig: ImageFilterConfig?
    
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
        displayTexture = filters[filter]?.preview
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
            try processFilterPreviews()
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
        
        filters[.original] = (original.makeCopy(device: metalContext.device, queue: metalContext.commandQueue),
                              nil)
        
        for name in ImageFilter.allCases {
            if name == .original { continue }
            filters[name] = (metalContext.device.makeTexture(descriptor: descriptor),
                             metalContext.device.makeTexture(descriptor: descriptor))
        }
    }
    
    func processFilterPreviews() throws {
        for name in ImageFilter.allCases {
            if name == .original { continue }
            guard let outputTexture = filters[name]?.preview else { continue }
            try process(filter: name, outputTexture: outputTexture, waitUntilCompleted: true) { computeEncoder in
                guard let config = self.filterConfigs[name] else { return }
                config.encode(into: computeEncoder)
            }
        }
    }
    
    func process(filter: ImageFilter,
                 outputTexture: MTLTexture,
                 waitUntilCompleted: Bool,
                 encodeCommands: @escaping (MTLComputeCommandEncoder) -> Void,
                 completedHandler: ((MTLCommandBuffer) -> Void)? = nil) throws {
        
        guard filter != .original else { return }
        guard !filters.isEmpty else { return }
        guard !filter.kernels.isEmpty else { return }
        guard let inputTexture = filters[.original]?.preview else { return }
        guard let commandBuffer = metalContext.commandQueue.makeCommandBuffer() else { return }
        
        guard let plan = try filter.makePlan(metalContext: metalContext,
                                             inputTexture: inputTexture,
                                             outputTexture: outputTexture,
                                             encodeCommands: encodeCommands) else { return }
        plan.encode(to: commandBuffer)
        
        if let completedHandler = completedHandler {
            commandBuffer.addCompletedHandler(completedHandler)
        }
        
        commandBuffer.commit()
        
        if waitUntilCompleted {
            commandBuffer.waitUntilCompleted()
        }
    }
    
    func requestReprocess(filter: ImageFilter, config: ImageFilterConfig) throws {
        guard let _ = filterConfigs[filter] else { return }
        
        Task {
            pendingConfig = config
            try await reprocessIfPossible(filter: filter)
        }
    }
    
    func reprocessIfPossible(filter: ImageFilter) async throws {
        
        guard let _ = filterConfigs[filter] else { return }
        guard !reprocessInProgress else { return }
        guard let config = pendingConfig else { return }
        guard let outputTexture = filters[filter]?.reprocessBuffer else { return }
        
        reprocessInProgress = true
        filterConfigs[filter] = pendingConfig
        pendingConfig = nil
        
        try process(filter: filter, outputTexture: outputTexture, waitUntilCompleted: false) { computeEncoder in
            config.encode(into: computeEncoder)
        } completedHandler: { commandBuffer in
            Task { @MainActor in
                let metalContext = self.metalContext
                self.displayTexture = outputTexture.makeCopy(device: metalContext.device, queue: metalContext.commandQueue)
                self.reprocessInProgress = false
                self.displayTextureRedrawID += 1
                do {
                    try await self.reprocessIfPossible(filter: filter)
                } catch {
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }
}
