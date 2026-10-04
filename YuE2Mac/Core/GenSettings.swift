//
//  GenSettings.swift — the user's chosen engine inputs, persisted in UserDefaults.
//

import Foundation
import Observation

/// Which interface the user wants: friendly & minimal, or full control.
enum UserMode: String, CaseIterable {
    case lite
    case pro
}

/// Advanced sampling overrides (Pro mode). Defaults mirror the engine's
/// generation config so an untouched Pro session behaves exactly like upstream.
struct SamplingOverrides: Codable, Equatable {
    var temperature: Double = 1.0
    var topP: Double = 0.95
    var topK: Double = 100
    var repetitionPenalty: Double = 1.2

    static let engineDefaults = SamplingOverrides()

    var isDefault: Bool { self == Self.engineDefaults }
}

/// Available model quantizations are discovered by scanning the engine folder,
/// but a model name can also be stored so it survives relaunch.
@Observable
final class SettingsStore {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard

    var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: "theme") }
    }

    /// LITE = simple guided UI; PRO = full toolbox. One-click toggle in the toolbar.
    var mode: UserMode {
        didSet { defaults.set(mode.rawValue, forKey: "mode") }
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
    /// Draft = 8-step fast preview; "Finish at full quality" upgrades it later.
    var draftPreview: Bool {
        didSet { defaults.set(draftPreview, forKey: "draftPreview") }
    }

    // Draggable column split (LITE & PRO): the fraction of the window width
    // that the right-hand controls column occupies. Persisted per mode; a
    // fresh install (no stored value) falls back to each mode's default.
    var liteSidebarFraction: Double {
        didSet { defaults.set(liteSidebarFraction, forKey: "liteSidebarFraction") }
    }
    var proSidebarFraction: Double {
        didSet { defaults.set(proSidebarFraction, forKey: "proSidebarFraction") }
    }

    /// Keep the split inside a band where both columns stay usable, whatever
    /// the window width or whatever was stored. Never returns NaN/infinite.
    static func clampSplit(_ f: Double, fallback: Double = 0.40) -> Double {
        guard f.isFinite else { return fallback }
        return min(0.60, max(0.25, f))
    }

    // Advanced sampling overrides (Pro mode).
    var temperature: Double {
        didSet { defaults.set(temperature, forKey: "temperature") }
    }
    var topP: Double {
        didSet { defaults.set(topP, forKey: "topP") }
    }
    var topK: Double {
        didSet { defaults.set(topK, forKey: "topK") }
    }
    var repPenalty: Double {
        didSet { defaults.set(repPenalty, forKey: "repPenalty") }
    }

    var samplingOverrides: SamplingOverrides {
        SamplingOverrides(temperature: temperature, topP: topP,
                          topK: topK, repetitionPenalty: repPenalty)
    }

    func resetSampling() {
        temperature = SamplingOverrides.engineDefaults.temperature
        topP = SamplingOverrides.engineDefaults.topP
        topK = SamplingOverrides.engineDefaults.topK
        repPenalty = SamplingOverrides.engineDefaults.repetitionPenalty
    }

    private init() {
        theme = AppTheme(rawValue: defaults.string(forKey: "theme") ?? "") ?? .studio
        mode = UserMode(rawValue: defaults.string(forKey: "mode") ?? "") ?? .lite
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
        draftPreview = defaults.bool(forKey: "draftPreview")
        liteSidebarFraction = Self.clampSplit(
            (defaults.object(forKey: "liteSidebarFraction") as? Double) ?? 0.36, fallback: 0.36)
        proSidebarFraction = Self.clampSplit(
            (defaults.object(forKey: "proSidebarFraction") as? Double) ?? 0.40, fallback: 0.40)

        let t = SamplingOverrides.engineDefaults
        temperature = defaults.object(forKey: "temperature") == nil ? t.temperature : defaults.double(forKey: "temperature")
        topP = defaults.object(forKey: "topP") == nil ? t.topP : defaults.double(forKey: "topP")
        topK = defaults.object(forKey: "topK") == nil ? t.topK : defaults.double(forKey: "topK")
        repPenalty = defaults.object(forKey: "repPenalty") == nil ? t.repetitionPenalty : defaults.double(forKey: "repPenalty")
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
