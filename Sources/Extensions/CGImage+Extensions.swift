//
//  CGImage+Extensions.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 25/5/26.
//

import CoreGraphics

extension CGImage {
    
    /// Normalizes the image into an 8-bit BGRA pixel layout in the device RGB color space.
    ///
    /// Photos can provide images in formats (wide-gamut, HDR, unusual bit depths) that
    /// `MTKTextureLoader` fails to decode. Converting to a standard 8-bit format makes
    /// texture creation much more robust.
    func normalizedForMTKTextureLoader() -> CGImage? {
        let width = self.width
        let height = self.height
        guard width > 0, height > 0 else { return nil }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bitsPerComponent = 8
        let bytesPerRow = width * bytesPerPixel
        
        // BGRA8, premultiplied alpha, little-endian (matches `.bgra8Unorm`).
        let bitmapInfo: CGBitmapInfo = [
            .byteOrder32Little,
            CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        ]
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }
        
        // Draw 1:1 into the context. Orientation is handled separately by UV mapping.
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }
}

