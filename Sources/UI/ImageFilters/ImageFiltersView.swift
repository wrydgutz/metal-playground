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
                    if let texture = viewModel.filters[viewModel.filter] {
                        MetalTextureView(metalContext: viewModel.metalContext,
                                         texture: texture,
                                         mapping: viewModel.textureMapping)
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
                                        viewModel.filter = filter
                                    } label: {
                                        VStack {
                                            Text(filter.title)
                                                .font(.caption)
                                                .foregroundStyle(.black)
                                            MetalTextureView(metalContext: viewModel.metalContext,
                                                             texture: texture,
                                                             mapping: viewModel.textureMapping)
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
