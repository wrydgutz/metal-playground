//
//  FloatSettingsView.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 9/5/26.
//

import SwiftUI

struct FloatSettingsView: View {
    
    @State var value: Float = 0.5
    var range: ClosedRange<Float> = 0.0...1.0
    var label: String
    var onUpdate: (Float) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.title3)
            
            HStack {
                Text("Factor")
                    .padding(.trailing, 50)
                
                Slider(value: $value, in: range) {
                    Text(label)
                } minimumValueLabel: {
                    Text(String(format: "%.1f", range.lowerBound))
                } maximumValueLabel: {
                    Text(String(format: "%.1f", range.upperBound))
                }
            }
        }
        .onChange(of: value) { _, newValue in
            onUpdate(newValue)
        }
    }
}

#Preview {
    FloatSettingsView(label: "Float Settings") { _ in }
}
