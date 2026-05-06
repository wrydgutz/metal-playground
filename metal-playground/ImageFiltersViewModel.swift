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

@MainActor
@Observable
final class ImageFiltersViewModel {
    
    var displayTexture: MTLTexture?
    
    @ObservationIgnored var metalContext = MetalContext()
    
    @ObservationIgnored private var commandBuffer: MTLCommandBuffer?
    @ObservationIgnored private var inputTexture: MTLTexture?
    @ObservationIgnored private var outputTexture: MTLTexture?
    
    
    init() {
        
    }
    
    func process(image: UIImage) {
        
        guard let cgImage = image.cgImage else { return }
        
        let loader = MTKTextureLoader(device: metalContext.device)
        
        do {
            displayTexture = try loader.newTexture(
                cgImage: cgImage,
                options: [
                    .origin: MTKTextureLoader.Origin.topLeft
                ]
            )
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
    
    func loadTextures(image: UIImage) {
        
        guard let cgImage = image.cgImage else { return }
        
        let loader = MTKTextureLoader(device: metalContext.device)
        
        do {
            inputTexture = try loader.newTexture(
                cgImage: cgImage,
                options: [
                    .origin: MTKTextureLoader.Origin.topLeft
                ]
            )
        } catch {
            print("Error: \(error.localizedDescription)")
        }
        
        
        guard let inputTexture = inputTexture else { return }
        
        let outputDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                                        width: inputTexture.width,
                                                                        height: inputTexture.height,
                                                                        mipmapped: false)
        outputDescriptor.usage = [.shaderRead, .shaderWrite]
        outputDescriptor.storageMode = .shared
        
        outputTexture = metalContext.device.makeTexture(descriptor: outputDescriptor)
    }
    
    func processGrayscale() throws {
        
        guard let inputTexture = inputTexture else { return }
        guard let outputTexture = outputTexture else { return }
        guard let commandBuffer = metalContext.commandQueue.makeCommandBuffer() else { return }
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        computeEncoder.setComputePipelineState(try metalContext.pipelineStateObjects.grayscale)
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
        
//        displayImage = makeUIImage(from: outputTexture)
    }
    
    func makeUIImage(from texture: MTLTexture) -> UIImage? {
        let width = texture.width
        let height = texture.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let byteCount = bytesPerRow * height
        
        var bytes = [UInt8](repeating: 0, count: byteCount)
        
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.getBytes(&bytes,
                         bytesPerRow: bytesPerRow,
                         from: region,
                         mipmapLevel: 0)
        
        guard texture.pixelFormat == .bgra8Unorm else {
            assertionFailure("makeUIImage(from:) expects bgra8Unorm")
            return nil
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: CGBitmapInfo = [
            .byteOrder32Little,
            CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        ]
        
        guard let provider = CGDataProvider(data: Data(bytes) as CFData) else {
            return nil
        }
        
        guard let cgImage = CGImage(width: width,
                                    height: height,
                                    bitsPerComponent: 8,
                                    bitsPerPixel: 32,
                                    bytesPerRow: bytesPerRow,
                                    space: colorSpace,
                                    bitmapInfo: bitmapInfo,
                                    provider: provider,
                                    decode: nil,
                                    shouldInterpolate: false,
                                    intent: .defaultIntent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}
