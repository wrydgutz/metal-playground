//
//  MTLTexture+Extensions.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 9/5/26.
//

import Metal

extension MTLTexture {
    
    func makeCopy(device: MTLDevice, queue: MTLCommandQueue) -> MTLTexture? {
        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: width,
            height: height,
            mipmapped: mipmapLevelCount > 1
        )
        desc.usage = usage.union([.shaderRead, .shaderWrite])
        desc.storageMode = storageMode

        guard let dst = device.makeTexture(descriptor: desc),
              let cb = queue.makeCommandBuffer(),
              let blit = cb.makeBlitCommandEncoder() else { return nil }

        blit.copy(
            from: self,
            sourceSlice: 0,
            sourceLevel: 0,
            sourceOrigin: .init(x: 0, y: 0, z: 0),
            sourceSize: .init(width: width, height: height, depth: 1),
            to: dst,
            destinationSlice: 0,
            destinationLevel: 0,
            destinationOrigin: .init(x: 0, y: 0, z: 0)
        )
        blit.endEncoding()
        cb.commit()
        cb.waitUntilCompleted()
        return dst
    }
}
