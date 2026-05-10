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
            
            ForEach(viewModel.filtersWithFloatConfigs) { filter in
                if viewModel.filter == filter {
                    let config = viewModel.filterConfigs[filter] as! FloatConfig
                    FloatSettingsView(value: config.value,
                                      range: config.range,
                                      label: "\(filter.title) Settings") { newValue in
                        do {
                            try viewModel.process(filter: filter) { config in
                                let floatConfig = config as! FloatConfig
                                floatConfig.value = newValue
                            }
                        } catch {
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                    .padding()
                }
            }
            
            ForEach(viewModel.filtersWithUIntConfigs) { filter in
                if viewModel.filter == filter {
                    let config = viewModel.filterConfigs[filter] as! UIntConfig
                    FloatSettingsView(value: Float(config.value),
                                      range: Float(config.range.lowerBound)...Float(config.range.upperBound),
                                      label: "\(filter.title) Settings") { newValue in
                        do {
                            try viewModel.process(filter: filter) { config in
                                let uint32Config = config as! UIntConfig
                                uint32Config.value = UInt(newValue)
                            }
                        } catch {
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                    .padding()
                }
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
