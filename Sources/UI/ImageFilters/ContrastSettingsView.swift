//
//  ContrastSettingsView.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 9/5/26.
//

import SwiftUI

struct ContrastSettingsView: View {
    
    @State var value: Float = 0.5
    var onUpdate: (Float) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Contrast Settings")
                .font(.title3)
            
            Slider(value: $value, in: 0.0...1.0) {
                Text("Brightness")
            } minimumValueLabel: {
                Text("0.0")
            } maximumValueLabel: {
                Text("1.0")
            }
        }
        .onChange(of: value) { _, newValue in
            onUpdate(newValue)
        }
    }
}

#Preview {
    ContrastSettingsView() { _ in }
}
