//
//  YuE2MacApp.swift
//  YuE2Mac — local AI songwriting on Apple Silicon.
//

import SwiftUI

@main
struct YuE2MacApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1080, height: 720)
    }
}