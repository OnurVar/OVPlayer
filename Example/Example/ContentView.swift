//
//  ContentView.swift
//  Example
//
//  Created by Onur Var on 29.03.2024.
//

import OVPlayer
import SwiftUI

struct ContentView: View {
    let sampleVideoURL1 = URL(string: "https://download.samplelib.com/mp4/sample-30s.mp4")!
    var body: some View {
        VStack {
            OVPlayerView(
                url: sampleVideoURL1,
                options: .init(autoPlayVideoWhenReady: true)
            )
            .aspectRatio(16 / 9, contentMode: .fit)
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
