//
//  ContentView.swift
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 5/5/26.
//

import SwiftUI

struct ContentView: View {
    
    enum Route: Hashable {
        case imageFilters
    }
    
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                VStack {
                    Text("Metal Playground")
                        .font(.title)
                    
                    Spacer()
                        .frame(height: 50)
                    
                    Button("Image Filters") {
                        path.append(Route.imageFilters)
                    }
                    
                    Spacer()
                }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                        case .imageFilters:
                            ImageFiltersView()
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
