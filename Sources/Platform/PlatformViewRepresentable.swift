//
//  PlatformViewRepresentable.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 23/5/26.
//

import SwiftUI

#if os(macOS)
typealias PlatformViewRepresentable = NSViewRepresentable
#else
typealias PlatformViewRepresentable = UIViewRepresentable
#endif
