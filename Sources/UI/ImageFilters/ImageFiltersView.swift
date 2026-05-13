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
                                if let texture = viewModel.filters[filter]?.preview {
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
            
            let filtersWithConfigs = viewModel.filterConfigs.keys.map(\.id)
            ForEach(filtersWithConfigs) { filter in
                if viewModel.filter == filter {
                    ForEach(viewModel.filterConfigs[filter]!.fields) { field in
                        ConfigFieldView(value: field.getValue(),
                                        range: field.getRange(),
                                        label: field.name) { newValue in
                            field.setValue(newValue)
                            
                            do {
                                try viewModel.requestReprocess(filter: filter,
                                                               config: viewModel.filterConfigs[filter]!)
                            } catch {
                                print("Error: \(error.localizedDescription)")
                            }
                        }
                        .padding(.horizontal)
                    }
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
