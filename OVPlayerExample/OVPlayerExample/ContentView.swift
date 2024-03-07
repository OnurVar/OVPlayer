//
//  ContentView.swift
//  OVPlayerExample
//
//  Created by Onur Var on 7.03.2024.
//

import SwiftUI


struct ContentView: View {
    var body: some View {
        
        VStack {
            OVPlayerView()
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
