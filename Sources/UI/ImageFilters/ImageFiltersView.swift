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
        HStack {
            #if os(macOS)
            ScrollView(.vertical, showsIndicators: true) {
                VStack {
                    filters(itemWidth: 100, itemHeight: 100)
                }
            }
            #endif // os(macOS)
            
            Spacer()
            
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
                
                #if os(iOS)
                GeometryReader { proxy in
                    let itemWidth: CGFloat = 100
                    let sideInset = max(0, (proxy.size.width - itemWidth) / 2)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            filters(itemWidth: itemWidth, itemHeight: 100)
                        }
                        .padding(.horizontal, sideInset)
                    }
                }
                .frame(height: 110)
                #endif // os(iOS)
                
                let filtersWithConfigs = viewModel.filterConfigs.keys.map(\.id)
                ForEach(filtersWithConfigs) { filter in
                    if viewModel.filter == filter,
                       let fields = viewModel.filterConfigs[filter]?.fields {
                        ForEach(fields) { field in
                            ConfigFieldView(value: field.getValue(),
                                            range: field.getRange(),
                                            label: field.name) { newValue in
                                field.setValue(newValue)
                                
                                do {
                                    try viewModel.requestReprocess(filter: filter)
                                } catch {
                                    print("Error: \(error.localizedDescription)")
                                }
                            }
                            .padding(.horizontal)
                            .frame(maxWidth: 500)
                        }
                    }
                }
                
                Spacer()
            }
            
            Spacer()
        }
        .navigationTitle("Image Filters")
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = PlatformImage(data: data) {
                    viewModel.process(image: image)
                }
            }
        }
    }
    
    @ViewBuilder
    func filters(itemWidth: CGFloat, itemHeight: CGFloat) -> some View {
        if viewModel.isProcessed && !viewModel.filters.isEmpty {
            ForEach(ImageFilter.allCases) { filter in
                if let texture = viewModel.filters[filter]?.preview {
                    Button {
                        viewModel.select(filter: filter)
                    } label: {
                        VStack {
                            Text(filter.title)
                                .font(.caption)
                                .foregroundStyle(Color(.systemGray))
                            MetalTextureView(metalContext: viewModel.metalContext,
                                             texture: texture,
                                             mapping: viewModel.textureMapping,
                                             redrawID: nil)
                        }
                    }
                    .frame(width: itemWidth, height: itemHeight)
                }
            }
        }
    }
}

#Preview {
    ImageFiltersView()
}
