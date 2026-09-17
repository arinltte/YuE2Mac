//
//  ContentView.swift — root: routes between one-time setup and the generator.
//

import SwiftUI

struct ContentView: View {
    @State private var setup = SetupManager()
    @State private var engine = GenerationEngine()

    var body: some View {
        Group {
            switch setup.state {
            case .idle, .installing, .failed:
                SetupView(setup: setup)
            case .ready:
                GeneratorView(setup: setup, engine: engine)
            }
        }
        .frame(minWidth: 900, minHeight: 640)
    }
}

#Preview {
    ContentView()
}