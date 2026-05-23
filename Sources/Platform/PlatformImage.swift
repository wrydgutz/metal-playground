//
//  PlatformImage.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 23/5/26.
//

import Foundation
import MetalKit

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage

extension PlatformImage {
    var cgImageForProcessing: CGImage? { cgImage }
    var textureMappingForDisplay: TextureMapping { imageOrientation.textureMapping }
}
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage

extension PlatformImage {
    var cgImageForProcessing: CGImage? {
        var proposedRect = CGRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &proposedRect, context: nil, hints: nil)
    }

    var textureMappingForDisplay: TextureMapping {
        // NSImage does not provide a UIImage-like orientation API. Most macOS images are
        // delivered already "upright", so default to identity for now.
        .identity
    }
}
#else
#error("Unsupported platform: expected UIKit or AppKit.")
#endif

