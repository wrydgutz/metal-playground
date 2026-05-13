//
//  ConfigFieldView.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 9/5/26.
//

import SwiftUI

struct ConfigFieldView: View {
    
    @State var value: Float = 0.5
    var range: ClosedRange<Float> = 0.0...1.0
    var label: String
    var onUpdate: (Float) -> Void
    
    var body: some View {
        HStack {
            Text(label)
                .padding(.trailing, 30)
            
            Slider(value: $value, in: range) {
                Text(label)
            } minimumValueLabel: {
                Text(String(format: "%.1f", range.lowerBound))
            } maximumValueLabel: {
                Text(String(format: "%.1f", range.upperBound))
            }
        }
        .onChange(of: value) { _, newValue in
            onUpdate(newValue)
        }
    }
}

#Preview {
    ConfigFieldView(label: "Intensity") { _ in }
}
