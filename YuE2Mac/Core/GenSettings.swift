//
//  GenSettings.swift — the user's chosen engine inputs, persisted in UserDefaults.
//

import Foundation
import Observation

/// Available model quantizations are discovered by scanning the engine folder,
/// but a model name can also be stored so it survives relaunch.
@Observable
final class SettingsStore {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard

    var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: "theme") }
    }

    /// Model variant the user chose at install time (defaults to the autoscanned one).
    var preferredVariant: String {
        get { defaults.string(forKey: "preferredVariant") ?? "" }
        set { defaults.set(newValue, forKey: "preferredVariant") }
    }

    var engineRoot: String? {
        didSet { defaults.set(engineRoot, forKey: "engineRoot") }
    }
    var modelDir: String? {
        didSet { defaults.set(modelDir, forKey: "modelDir") }
    }

    // Persisted generation preferences.
    var style: String {
        didSet { defaults.set(style, forKey: "style") }
    }
    var lyrics: String {
        didSet { defaults.set(lyrics, forKey: "lyrics") }
    }
    var planning: String {          // off | melody | full
        didSet { defaults.set(planning, forKey: "planning") }
    }
    var steps: Double {
        didSet { defaults.set(steps, forKey: "steps") }
    }
    var cfgScale: Double {
        didSet { defaults.set(cfgScale, forKey: "cfgScale") }
    }
    var maxTokens: Double {
        didSet { defaults.set(maxTokens, forKey: "maxTokens") }
    }
    var seed: String {
        didSet { defaults.set(seed, forKey: "seed") }
    }
    var instrumental: Bool {
        didSet { defaults.set(instrumental, forKey: "instrumental") }
    }

    private init() {
        theme = AppTheme(rawValue: defaults.string(forKey: "theme") ?? "") ?? .studio
        engineRoot = defaults.string(forKey: "engineRoot")
        modelDir = defaults.string(forKey: "modelDir")
        style = defaults.string(forKey: "style") ?? "English, indie pop, bright acoustic guitar, soft drums, warm lead vocal"
        lyrics = defaults.string(forKey: "lyrics") ?? ""
        planning = defaults.string(forKey: "planning") ?? "full"
        steps = defaults.double(forKey: "steps") != 0 ? defaults.double(forKey: "steps") : 32
        cfgScale = defaults.double(forKey: "cfgScale") != 0 ? defaults.double(forKey: "cfgScale") : 5.0
        maxTokens = defaults.double(forKey: "maxTokens") != 0 ? defaults.double(forKey: "maxTokens") : 4500
        seed = defaults.string(forKey: "seed") ?? ""
        instrumental = defaults.bool(forKey: "instrumental")
    }

    /// Fold the instrumental toggle into the real style prompt sent to the model.
    func effectiveStyle() -> String {
        guard instrumental else { return style }
        let base = style.trimmingCharacters(in: .whitespacesAndNewlines)
        let suffix = "instrumental, no vocals"
        return base.isEmpty ? suffix : base + ", " + suffix
    }

    /// Strip lyrics to structure tags only for instrumentals (the model's known quirk).
    func effectiveLyrics() -> String {
        guard instrumental else { return lyrics }
        let lines = lyrics.components(separatedBy: .newlines)
        let tags = lines.filter { line in
            line.hasPrefix("[") && line.hasSuffix("]")
        }
        return tags.count > 0 ? tags.joined(separator: "\n") : "[Intro]\n[Instrumental]"
    }

    /// A seed actually passed to the CLI. Empty → a fresh random seed.
    func resolvedSeed() -> Int? {
        let trimmed = seed.trimmingCharacters(in: .whitespaces)
        if let n = Int(trimmed) { return n }
        return Int.random(in: 0...999_999)
    }
}