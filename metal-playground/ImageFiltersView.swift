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
                if let texture = viewModel.displayTexture {
                    MetalTextureView(metalContext: viewModel.metalContext, texture: texture)
                        .scaledToFit()
                }
            }
            .frame(height: 500)

            PhotosPicker("Pick Image", selection: $selectedItem, matching: .images)
            
            Spacer()
            
            HStack {
                // TODO: Add Filter Options
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
