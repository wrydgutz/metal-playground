//
//  ImageFiltersView.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 5/5/26.
//

import SwiftUI
import PhotosUI

struct ImageFiltersView: View {
    
    @State private var selectedItem: PhotosPickerItem?
    
    @State private var viewModel = ImageFiltersViewModel()
    
    var body: some View {
        VStack {
            VStack {
                if viewModel.isProcessed && !viewModel.filters.isEmpty {
                    if let texture = viewModel.displayTexture {
                        MetalTextureView(metalContext: viewModel.metalContext,
                                         texture: texture,
                                         mapping: viewModel.textureMapping,
                                         redrawID: viewModel.displayTextureRedrawID)
                            .scaledToFit()
                    }
                }
            }
            .frame(height: 500)

            PhotosPicker("Pick Image", selection: $selectedItem, matching: .images)
            
            Spacer()
            
            GeometryReader { proxy in
                let itemWidth: CGFloat = 100
                let sideInset = max(0, (proxy.size.width - itemWidth) / 2)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        if viewModel.isProcessed && !viewModel.filters.isEmpty {
                            ForEach(ImageFilter.allCases) { filter in
                                if let texture = viewModel.filters[filter] {
                                    Button {
                                        viewModel.select(filter: filter)
                                    } label: {
                                        VStack {
                                            Text(filter.title)
                                                .font(.caption)
                                                .foregroundStyle(.black)
                                            MetalTextureView(metalContext: viewModel.metalContext,
                                                             texture: texture,
                                                             mapping: viewModel.textureMapping,
                                                             redrawID: nil)
                                        }
                                    }
                                    .frame(width: itemWidth, height: 100)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, sideInset)
                }
            }
            .frame(height: 110)
            
            if viewModel.filter == .brightness {
                let config = viewModel.filterConfigs[.brightness] as! BrightnessConfig
                BrightnessSettingsView(value: config.value) { newValue in
                    do {
                        try viewModel.process(filter: .brightness) { config in
                            let brightnessConfig = config as! BrightnessConfig
                            brightnessConfig.value = newValue
                        }
                    } catch {
                        print("Error: \(error.localizedDescription)")
                    }
                }
                .padding()
            } else if viewModel.filter == .contrast {
                let config = viewModel.filterConfigs[.contrast] as! ContrastConfig
                ContrastSettingsView(value: config.value) { newValue in
                    do {
                        try viewModel.process(filter: .contrast) { config in
                            let contrastConfig = config as! ContrastConfig
                            contrastConfig.value = newValue
                        }
                    } catch {
                        print("Error: \(error.localizedDescription)")
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Image Filters")
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    viewModel.process(image: uiImage)
                }
            }
        }
    }
}

#Preview {
    ImageFiltersView()
}
