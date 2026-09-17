//
//  GeneratorView.swift — writing canvas on the left, card toolbox + actions on
//  the right, and a single friendly status/result panel at the bottom-left.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct GeneratorView: View {
    @Bindable var setup: SetupManager
    @Bindable var engine: GenerationEngine
    @Bindable private var settings = SettingsStore.shared

    @State private var outputPath = defaultOutputPath()
    @State private var showSettings = false
    @State private var showAbout = false

    private var theme: AppTheme { settings.theme }

    private var modelOptions: [String] {
        guard let root = settings.engineRoot else { return [] }
        return SetupManager.availableModels(engineRoot: root)
    }

    private var canGenerate: Bool {
        !engine.isRunning &&
        !settings.effectiveStyle().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !settings.effectiveLyrics().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            AmbientThemeBackground(theme: theme).ignoresSafeArea()

            GeometryReader { g in
                HStack(alignment: .top, spacing: 0) {
                    leftPanel
                        .frame(width: g.size.width * 0.66, height: g.size.height)
                    Divider().opacity(0.6)
                    rightPanel
                        .frame(width: g.size.width * 0.34, height: g.size.height)
                }
            }
        }
        .frame(minWidth: 900, minHeight: 640)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                themeMenu
                Button { showAbout.toggle() } label: { Image(systemName: "info.circle") }
                    .help("About YuE2Mac")
                    .popover(isPresented: $showAbout) { aboutContent }
                Button { showSettings = true } label: { Image(systemName: "gearshape") }
                    .help("Engine setup")
            }
        }
        .sheet(isPresented: $showSettings) { SettingsSheet(setup: setup) }
    }

    // MARK: - Left: writing canvas

    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            // Lyrics & Style (fills the space)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Lyrics & Style").font(.system(.title2, design: .rounded, weight: .semibold))
                    Spacer()
                    Button { settings.lyrics = "" } label: { Image(systemName: "trash") }
                        .buttonStyle(.plain).foregroundStyle(.secondary).help("Clear lyrics")
                }

                CardContainer(theme: theme) {
                    VStack(alignment: .leading, spacing: 12) {
                        styleField
                        Divider()
                        tagsRow
                        lyricsEditor
                    }
                    .padding(12)
                }
            }
            .frame(maxHeight: .infinity)

            resultPanel
        }
        .padding(20)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(theme.accentColor)
            VStack(alignment: .leading, spacing: 1) {
                Text("YuE2Mac").font(.system(.title, design: .rounded, weight: .bold))
                Text(modelSummary).font(.system(.caption)).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var modelSummary: String {
        let name = settings.modelDir.flatMap { URL(fileURLWithPath: $0).lastPathComponent }.map { "\($0)" } ?? "no model"
        return "\(SystemInfo.chipName) · \(name)"
    }

    private var styleField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Style prompt", systemImage: "slider.horizontal.3")
                    .font(.system(.body, weight: .semibold))
                Spacer()
                HelpButton(text: "Describe the music's mood and instruments. Press the arrow to cycle through ready-made starters.")
                Button { shuffleStyle() } label: { Image(systemName: "arrow.clockwise") }
                    .buttonStyle(.borderless).controlSize(.small)
                    .foregroundStyle(theme.accentColor)
                    .help("Use a different starter style")
            }
            TextField("English, indie pop, bright acoustic guitar, soft drums…",
                      text: $settings.style, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(.body))
                .lineLimit(1...3)
                .padding(10)
                .background(fieldFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(fieldBorder, lineWidth: 1))
        }
    }

    private var tagsRow: some View {
        HStack(spacing: 6) {
            ForEach(["Intro", "Verse", "Chorus", "Bridge", "Outro", "Instrumental"], id: \.self) { tag in
                Button("[\(tag)]") { insertTag(tag) }
                    .buttonStyle(.borderless).controlSize(.small).foregroundStyle(theme.accentColor)
            }
            Spacer()
            Menu {
                ForEach(Presets.lyrics, id: \.name) { set in
                    Button(set.name) { settings.lyrics = set.text }
                }
            } label: {
                Label("Samples", systemImage: "text.book.closed")
            }
            .menuStyle(.borderlessButton).controlSize(.small).fixedSize()
            .help("Load a ready-made set of lyrics")

            Toggle(isOn: $settings.instrumental) {
                HStack(spacing: 4) { Text("Instrumental"); HelpButton(text: "Adds “instrumental, no vocals” to the prompt and strips lyrics to structure tags.") }
            }
            .toggleStyle(.switch).controlSize(.mini)
        }
    }

    private var lyricsEditor: some View {
        ZStack(alignment: .bottomTrailing) {
            TextEditor(text: $settings.lyrics)
                .font(.system(.body))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 170)
                .background(fieldFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(fieldBorder, lineWidth: 1))
            Text("\(settings.lyrics.count) characters")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.tertiary).padding(.trailing, 14).padding(.bottom, 8)
        }
    }

    /// Shared, friendly status + result panel (bottom-left "audio playing" area).
    private var resultPanel: some View {
        CardContainer(theme: theme) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        Circle().fill(theme.accentColor.opacity(0.15)).frame(width: 30, height: 30)
                        resultIcon.font(.system(size: 14, weight: .semibold))
                    }
                    Text(resultTitle).font(.system(.title3))
                    Spacer()
                    if engine.isRunning { ProgressView().controlSize(.small) }
                }

                if engine.isRunning {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(processingText).font(.system(.body)).foregroundStyle(.primary)
                        ProgressView(value: progressFraction)
                            .progressViewStyle(.linear).tint(theme.accentColor)
                        if !engine.detailLine.isEmpty {
                            Text(engine.detailLine).font(.system(.footnote, design: .monospaced)).foregroundStyle(.tertiary)
                        }
                    }
                } else if let url = engine.outputURL, engine.phase == .finished, FileManager.default.fileExists(atPath: url.path) {
                    AudioPlayer(url: url)
                    HStack {
                        if FileManager.default.fileExists(atPath: url.deletingPathExtension().appendingPathExtension("abc").path) {
                            Button { NSWorkspace.shared.open(url.deletingPathExtension().appendingPathExtension("abc")) } label: { Label("ABC score", systemImage: "doc.plaintext") }
                        }
                        Button { NSWorkspace.shared.activateFileViewerSelecting([url]) } label: { Label("Show in Finder", systemImage: "folder") }
                        Spacer()
                    }
                    .controlSize(.small)
                } else {
                    idleText
                }
            }
            .padding(12)
            .frame(minHeight: 96)
        }
        .frame(height: 150)
    }

    private var progressFraction: Double { engine.progress ?? 0 }

    private let idleText = Text("Each song is made in a few minutes and lives right on your Mac. Write lyrics, pick a style, then press **Generate Song**.")

    @ViewBuilder
    private var resultIcon: some View {
        switch engine.phase {
        case .preparing, .planning, .ar, .nar, .decoding, .writing: Image(systemName: "waveform").foregroundStyle(theme.accentColor)
        case .finished: Image(systemName: "checkmark").foregroundStyle(.green)
        case .failed, .cancelled: Image(systemName: "xmark").foregroundStyle(.red)
        default: Image(systemName: "sparkles").foregroundStyle(theme.accentColor)
        }
    }

    private var resultTitle: String {
        switch engine.phase {
        case .idle: return "Now playing"
        case .finished: return "Your song is ready"
        case .failed: return "Something went wrong"
        case .cancelled: return "Stopped"
        default: return "Making your song"
        }
    }

    private var processingText: String {
        switch engine.phase {
        case .preparing: return "Getting your prompt ready…"
        case .planning:  return "Sketching the arrangement…"
        case .ar:        return "Composing the melody…"
        case .nar:       return "Refining the sound…"
        case .decoding:  return "Rendering the audio…"
        case .writing:   return "Finalising the file…"
        case .failed:    return "Generation ended with an error."
        case .cancelled: return "Generation stopped."
        default:         return "Working…"
        }
    }

    // MARK: - Right: toolbox & actions

    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            modelCard
            qualityCard
            lengthCard
            seedCard
            Spacer()
            actionButtons
        }
        .padding(16)
    }

    private var modelCard: some View {
        CardContainer(theme: theme) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Model & Planning", systemImage: "gauge.with.dots.needle.bottom.50percent")
                    .font(.system(.body, weight: .semibold))
                alignRow(title: "Brain", help: "Which model to generate with.") {
                    Picker("", selection: Binding(
                        get: { settings.modelDir ?? "" },
                        set: { settings.modelDir = $0 }
                    )) {
                        ForEach(modelOptions, id: \.self) { path in
                            Text(URL(fileURLWithPath: path).lastPathComponent).tag(path)
                        }
                    }
                    .labelsHidden().fixedSize()
                }
                alignRow(title: "Planning (COT)", help: "Simulate an outline first? Full writes a chord chart, Off goes straight to audio.") {
                    Picker("", selection: $settings.planning) {
                        Text("Full — chords + melody").tag("full")
                        Text("Melody only").tag("melody")
                        Text("Off — fastest").tag("off")
                    }
                    .labelsHidden().fixedSize()
                }
            }
            .padding(12)
        }
    }

    private var qualityCard: some View {
        CardContainer(theme: theme) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Quality", systemImage: "waveform.path").font(.system(.body, weight: .semibold))
                labeledSlider("Refinement steps", $settings.steps, 10...100, whole: true, theme: theme,
                              help: "How many times the audio is refined. 32 is a good default.")
                labeledSlider("CFG — obedience", $settings.cfgScale, 1...15, whole: false, theme: theme,
                              help: "Higher follows your style more strictly; lower is more creative.")
            }
            .padding(12)
        }
    }

    private var lengthCard: some View {
        CardContainer(theme: theme) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Song length", systemImage: "clock").font(.system(.body, weight: .semibold))
                labeledSlider("Max tokens", $settings.maxTokens, 500...10000, whole: true, theme: theme, step: 250,
                              help: "≈25 tokens per second. 4500 ≈ 3 minutes.")
            }
            .padding(12)
        }
    }

    private var seedCard: some View {
        CardContainer(theme: theme) {
            VStack(alignment: .leading, spacing: 8) {
                alignRow(title: "Seed", help: "Same lyrics + same seed = the same song. Leave blank for a random one.") {
                    TextField("Random", text: $settings.seed)
                        .textFieldStyle(.plain)
                        .font(.system(.body, design: .monospaced))
                        .multilineTextAlignment(.trailing)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(fieldFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .frame(width: 110)
                }
            }
            .padding(12)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 8) {
            Button {
                if engine.isRunning { engine.cancel() } else { generate() }
            } label: {
                HStack {
                    if engine.isRunning {
                        Image(systemName: "stop.fill")
                        Text("Stop").fontWeight(.semibold)
                    } else {
                        Image(systemName: "sparkles")
                        Text("Generate Song").fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(engine.isRunning ? Color.red : theme.accentColor)
            .controlSize(.large)
            .disabled(!engine.isRunning && !canGenerate)

            Button(action: chooseOutput) {
                Label("Save to…", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
            }
            .buttonStyle(.bordered).controlSize(.large)
        }
    }

    // MARK: - Toolbar extras

    private var themeMenu: some View {
        Menu {
            ForEach(AppTheme.allCases) { t in
                Button { settings.theme = t } label: {
                    if t == settings.theme { Label(t.displayName, systemImage: "checkmark") } else { Text(t.displayName) }
                }
            }
        } label: { Image(systemName: "paintpalette") }
        .help("Appearance")
    }

    private var aboutContent: some View {
        VStack(spacing: 12) {
            if let nsImage = NSImage(named: "AppIcon") {
                Image(nsImage: nsImage)
                    .resizable().frame(width: 64, height: 64).cornerRadius(14)
            } else {
                Image(systemName: "music.note.list").font(.system(size: 34, weight: .bold))
                    .foregroundStyle(theme.accentColor)
            }
            Text("YuE2Mac").font(.system(.title3, design: .rounded, weight: .bold))
            Text("Version \(appVersion)")
                .font(.system(.caption)).foregroundStyle(.secondary)
            Text("Model: YuE2-3B (8-bit MLX)")
                .font(.system(.caption2)).foregroundStyle(.tertiary)

            Button(action: checkForUpdates) {
                Text(updateStatusText)
                    .font(.system(.caption))
                    .foregroundStyle(updateURL != nil ? Color.white : Color.primary)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(updateURL != nil ? theme.accentColor : Color.gray.opacity(0.25), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(updateStatusText == "Checking…" || updateStatusText == "Up to date")
        }
        .padding(20).frame(width: 240)
        .onAppear { if !didCheckUpdate { checkForUpdates() } }
    }

    @State private var updateStatusText = "Check for Updates"
    @State private var updateURL: URL?
    @State private var didCheckUpdate = false

    private var appVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
    }

    private func checkForUpdates() {
        if let url = updateURL { NSWorkspace.shared.open(url); return }
        updateStatusText = "Checking…"
        didCheckUpdate = true
        Task {
            let releases = URL(string: "https://github.com/arinltte/YuE2Mac/releases/latest")!
            var req = URLRequest(url: releases); req.httpMethod = "HEAD"
            guard let (_, resp) = try? await URLSession.shared.data(for: req),
                  let tag = resp.url?.lastPathComponent.trimmingCharacters(in: .whitespaces)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "v")), !tag.isEmpty else {
                await MainActor.run { updateStatusText = "Check for Updates" }; return
            }
            let newer = tag.compare(appVersion, options: .numeric) == .orderedDescending
            await MainActor.run {
                if newer {
                    updateStatusText = "New version available"
                    updateURL = URL(string: "https://github.com/arinltte/YuE2Mac/releases")
                } else {
                    updateStatusText = "Up to date"
                }
            }
        }
    }

    // MARK: - Actions & helpers

    private func shuffleStyle() {
        guard !Presets.styles.isEmpty else { return }
        if let idx = Presets.styles.firstIndex(of: settings.style) {
            settings.style = Presets.styles[(idx + 1) % Presets.styles.count]
        } else {
            settings.style = Presets.styles[0]
        }
    }

    private func insertTag(_ tag: String) {
        settings.lyrics += (settings.lyrics.isEmpty ? "" : "\n") + "[\(tag)]\n"
    }

    private func generate() {
        guard let root = settings.engineRoot, let model = settings.modelDir else { return }
        let fm = FileManager.default
        let parent = (outputPath as NSString).deletingLastPathComponent
        if !fm.fileExists(atPath: parent) { try? fm.createDirectory(atPath: parent, withIntermediateDirectories: true) }
        vmDrain()
        let out = fm.fileExists(atPath: outputPath)
            ? uniquedURL(for: URL(fileURLWithPath: outputPath))
            : URL(fileURLWithPath: outputPath)
        outputPath = out.path
        engine.generate(settings: settings, engineRoot: root, modelDir: model, output: out)
    }

    private func uniquedURL(for url: URL) -> URL {
        var candidate = url
        var counter = 2
        let fm = FileManager.default
        while fm.fileExists(atPath: candidate.path) {
            let stem = url.deletingPathExtension().path
            candidate = URL(fileURLWithPath: "\(stem) \(counter).wav")
            counter += 1
        }
        return candidate
    }

    private func chooseOutput() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.wav]
        panel.nameFieldStringValue = "my-song.wav"
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url { outputPath = url.path }
    }

    private var fieldFill: Color { Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.05) }
    private var fieldBorder: Color { Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.10) }

    private func vmDrain() {
        // no-op placeholder; reserved for future memory-return hygiene
    }
}

// MARK: - Reusable controls

/// An inline “?” that explains on hover and shows a popover on click.
struct HelpButton: View {
    let text: String
    @State private var show = false

    var body: some View {
        Button {
            show.toggle()
        } label: {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 12)).foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help(text)
        .popover(isPresented: $show, arrowEdge: .bottom) {
            Text(text)
                .font(.system(.caption))
                .foregroundStyle(.primary)
                .padding(12).frame(width: 230)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// A label on the left with an optional help icon, and its control pinned right.
private func alignRow<Content: View>(title: String, help: String? = nil,
                                     @ViewBuilder _ content: () -> Content) -> some View {
    HStack {
        HStack(spacing: 4) {
            Text(title).font(.system(.callout)).foregroundStyle(.secondary)
            if let help { HelpButton(text: help) }
        }
        Spacer()
        content()
    }
}

private func labeledSlider(_ title: String,
                           _ bound: Binding<Double>,
                           _ range: ClosedRange<Double>,
                           whole: Bool,
                           theme: AppTheme,
                           step: Double = 1,
                           help: String = "") -> some View {
    VStack(alignment: .leading, spacing: 3) {
        HStack {
            HStack(spacing: 4) {
                Text(title).font(.system(.callout)).foregroundStyle(.secondary)
                HelpButton(text: help)
            }
            Spacer()
            Text(formatValue(bound.wrappedValue, whole: whole))
                .font(.system(.subheadline, design: .monospaced)).foregroundStyle(.primary)
        }
        Slider(value: bound, in: range, step: step).tint(theme.accentColor)
    }
}

private func formatValue(_ v: Double, whole: Bool) -> String {
    whole ? "\(Int(v))" : String(format: "%.1f", v)
}

private func defaultOutputPath() -> String {
    AppPaths.outputDir.appendingPathComponent("song.wav").path
}