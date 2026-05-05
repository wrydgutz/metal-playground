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
    @State private var image: UIImage?
    
    var body: some View {
        VStack {
            VStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
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
                    image = uiImage
                }
            }
        }
    }
}

#Preview {
    ImageFiltersView()
}
