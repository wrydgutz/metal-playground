//
//  MetalTextureView.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 5/5/26.
//

import SwiftUI
import MetalKit

struct MetalTextureView: UIViewRepresentable {
    
    let metalContext: MetalContext
    let texture: MTLTexture
    
    func makeCoordinator() -> Coordinator {
        Coordinator(metalContext: metalContext, texture: texture)
    }
    
    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: metalContext.device)
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        view.delegate = context.coordinator
        view.isPaused = true
        view.enableSetNeedsDisplay = true
        return view
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.texture = texture
        uiView.setNeedsDisplay()
    }
}

extension MetalTextureView {
    
    final class Coordinator: NSObject, MTKViewDelegate {
        
        private let metalContext: MetalContext
        var texture: MTLTexture {
            didSet { verticesDirty = true }
        }
        
        private var vertexBuffer: MTLBuffer
        private var viewportSize: CGSize {
            didSet { verticesDirty = true }
        }
        
        private var verticesDirty = true
        
        init(metalContext: MetalContext, texture: MTLTexture) {
            self.metalContext = metalContext
            self.texture = texture
            self.viewportSize = .zero
            
            // Initialize the vertex buffer.
            let vertices = [MetalContext.TextureViewVertexData].init(
                repeating: .init(positionPixels: [0.0, 0.0], textureCoordinate: [0.0, 0.0]),
                count: 6
            )
            
            guard let vertexBuffer = metalContext.device.makeBuffer(
                bytes: vertices,
                length: vertices.count * MemoryLayout<MetalContext.TextureViewVertexData>.stride) else {
                fatalError("Could not create vertex buffer")
            }
            
            self.vertexBuffer = vertexBuffer
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            viewportSize = size
        }
        
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable else { return }
            guard let commandBuffer = metalContext.commandQueue.makeCommandBuffer() else { return }
            
            updateVerticesIfNeeded()
            
            // Draw into texture, clear it first, keep the result.
            // i.e. Draw once
            let descriptor = MTLRenderPassDescriptor()
            descriptor.colorAttachments[0].texture = drawable.texture
            descriptor.colorAttachments[0].loadAction = .clear
            descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
            descriptor.colorAttachments[0].storeAction = .store
            
            guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
                return
            }
            
            do {
                encoder.setRenderPipelineState(try metalContext.pipelineStateObjects.textureView)
            } catch {
                print("Error: \(error.localizedDescription)")
            }
            
            // Set vertex shader args
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            
            var viewportSizeVec = vector_uint2(UInt32(viewportSize.width), UInt32(viewportSize.height))
            encoder.setVertexBytes(&viewportSizeVec, length: MemoryLayout<vector_uint2>.size, index: 1)
            
            // Set fragment shader args
            encoder.setFragmentTexture(texture, index: 0)
            
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            encoder.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
        
        private func updateVerticesIfNeeded() {
            
            guard verticesDirty else { return }
            
            // Compute for the quad's vertices.
            // The vertices are computed to fit the texture to the viewport.
            let textureSize = CGSize(width: texture.width, height: texture.height)
            let scale = min(viewportSize.width / textureSize.width, viewportSize.height / textureSize.height)
            let quadSize = CGSize(width: textureSize.width * scale, height: textureSize.height * scale)
            let halfExtents: (Float, Float) = (Float(quadSize.width) * 0.5, Float(quadSize.height) * 0.5)
            
            let vertices: [MetalContext.TextureViewVertexData] = [
                .init(positionPixels: [halfExtents.0, -halfExtents.1], textureCoordinate: [1.0, 1.0]),
                .init(positionPixels: [-halfExtents.0, -halfExtents.1], textureCoordinate: [0.0, 1.0]),
                .init(positionPixels: [-halfExtents.0, halfExtents.1], textureCoordinate: [0.0, 0.0]),

                .init(positionPixels: [halfExtents.0, -halfExtents.1], textureCoordinate: [1.0, 1.0]),
                .init(positionPixels: [-halfExtents.0, halfExtents.1], textureCoordinate: [0.0, 0.0]),
                .init(positionPixels: [halfExtents.0, halfExtents.1], textureCoordinate: [1.0, 0.0])
            ]
            
            let length = vertices.count * MemoryLayout<MetalContext.TextureViewVertexData>.stride
            let _ = vertices.withUnsafeBytes { raw in
                memcpy(vertexBuffer.contents(), raw.baseAddress!, length)
            }
            
            verticesDirty = false
        }
    }
}

#Preview {
    let metalContext = MetalContext()
    
    let texture: MTLTexture = {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: 2,
            height: 2,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead]
        descriptor.storageMode = .shared
        
        let texture = metalContext.device.makeTexture(descriptor: descriptor)!
        
        // BGRA8: 2x2 pixels (blue, green, red, white)
        let bytes: [UInt8] = [
            255, 0, 0, 255,
            0, 255, 0, 255,
            0, 0, 255, 255,
            255, 255, 255, 255
        ]
        
        texture.replace(
            region: MTLRegionMake2D(0, 0, 2, 2),
            mipmapLevel: 0,
            withBytes: bytes,
            bytesPerRow: 2 * 4
        )
        
        return texture
    }()
    
    MetalTextureView(metalContext: metalContext, texture: texture)
}
