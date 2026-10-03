//
//  LiteModeView.swift — the friendly face of YuE2Mac. Two steps (pick a vibe,
//  write lyrics), one big button, and nothing else to learn. Everything
//  advanced (model, queue, sampling, scores) lives in Pro mode.
//

import SwiftUI

struct LiteModeView: View {
    @Bindable var engine: GenerationEngine
    var onOpenLibrary: () -> Void
    var onWriteLyrics: () -> Void

    @Bindable private var settings = SettingsStore.shared
    @State private var selectedVibe: String?

    private var theme: AppTheme { settings.theme }

    private var canGenerate: Bool {
        !settings.effectiveStyle().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !settings.effectiveLyrics().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var litePresets: [StylePreset] {
        StylePreset.litePicks.compactMap { StyleCatalog.preset(named: $0) }
    }

    var body: some View {
        GeometryReader { g in
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    vibeCard
                    lyricsCard
                    ResultPanel(engine: engine, theme: theme, lite: true)
                        .frame(maxHeight: 190)
                }
                .padding(20)
                .frame(width: g.size.width * 0.64, height: g.size.height)

                Divider().opacity(0.6)

                VStack(alignment: .leading, spacing: 12) {
                    generateCard
                    optionsCard
                    tipsCard
                    Spacer()
                }
                .padding(16)
                .frame(width: g.size.width * 0.36, height: g.size.height)
            }
        }
    }

    // MARK: Header

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
            ChipBadge(text: "LITE", tint: theme.accentColor)
        }
    }

    private var modelSummary: String {
        let name = settings.modelDir.flatMap { URL(fileURLWithPath: $0).lastPathComponent } ?? "no model"
        return "Your songs are made on this \(SystemInfo.chipName) · \(name)"
    }

    // MARK: Step 1 — vibe

    private var vibeCard: some View {
        CardContainer(theme: theme) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("1 · Pick a vibe", systemImage: "paintpalette")
                        .font(.system(.body, weight: .semibold))
                    Spacer()
                    Button { shuffleStyle() } label: { Label("Surprise me", systemImage: "dice") }
                        .buttonStyle(.borderless).controlSize(.small)
                        .foregroundStyle(theme.accentColor)
                        .help("Pick a random style for you")
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 8)], spacing: 8) {
                    ForEach(litePresets) { preset in
                        vibeChip(preset)
                    }
                }

                HStack(spacing: 8) {
                    Menu {
                        ForEach(StyleCatalog.categories, id: \.self) { category in
                            Menu(category) {
                                ForEach(StyleCatalog.presets(in: category)) { preset in
                                    Button("\(preset.emoji) \(preset.name)") {
                                        settings.style = preset.prompt
                                        selectedVibe = preset.id
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("More vibes…", systemImage: "plus.circle.dashed")
                            .font(.system(.callout))
                    }
                    .menuStyle(.borderlessButton).controlSize(.small).fixedSize()
                    .foregroundStyle(theme.accentColor)

                    TextField("…or describe your own style", text: $settings.style, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(.body))
                        .lineLimit(1...2)
                        .fieldLook()
                        .onChange(of: settings.style) { _, new in
                            if StyleCatalog.preset(forPrompt: new)?.id != selectedVibe {
                                selectedVibe = StyleCatalog.preset(forPrompt: new)?.id
                            }
                        }
                }
            }
            .padding(12)
        }
    }

    private func vibeChip(_ preset: StylePreset) -> some View {
        let selected = selectedVibe == preset.id
        return Button {
            settings.style = preset.prompt
            selectedVibe = preset.id
        } label: {
            HStack(spacing: 5) {
                Text(preset.emoji).font(.system(size: 15))
                Text(preset.name).font(.system(.callout, weight: selected ? .semibold : .regular))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                selected ? theme.accentColor.opacity(0.22) : Color.white.opacity(0.05),
                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(selected ? theme.accentColor : Color.white.opacity(0.08), lineWidth: selected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .help(preset.prompt)
    }

    // MARK: Step 2 — lyrics

    private var lyricsCard: some View {
        CardContainer(theme: theme) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("2 · Write your lyrics", systemImage: "text.quote")
                        .font(.system(.body, weight: .semibold))
                    Spacer()
                    if LyricWriter.isAvailable {
                        Button(action: onWriteLyrics) {
                            Label("Write with AI", systemImage: "wand.and.stars")
                        }
                        .buttonStyle(.borderless).controlSize(.small)
                        .foregroundStyle(theme.accentColor)
                        .help("Write lyrics on-device with Apple Intelligence")
                    }
                    Menu {
                        ForEach(Presets.lyrics, id: \.name) { set in
                            Button(set.name) { settings.lyrics = set.text }
                        }
                    } label: {
                        Label("Samples", systemImage: "text.book.closed")
                    }
                    .menuStyle(.borderlessButton).controlSize(.small).fixedSize()
                    .help("Load a ready-made set of lyrics")

                    Button { settings.lyrics = "" } label: { Image(systemName: "trash") }
                        .buttonStyle(.borderless).controlSize(.small)
                        .foregroundStyle(.secondary).help("Clear lyrics")
                }

                TextEditor(text: $settings.lyrics)
                    .font(.system(.body))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 150, maxHeight: .infinity)
                    .fieldLook()

                HStack(spacing: 6) {
                    ForEach(["Verse", "Chorus", "Bridge", "Outro"], id: \.self) { tag in
                        Button("[\(tag)]") { insertTag(tag) }
                            .buttonStyle(.borderless).controlSize(.small).foregroundStyle(theme.accentColor)
                    }
                    Text("\(settings.lyrics.count) characters")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
            }
            .padding(12)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: Right column

    private var generateCard: some View {
        VStack(spacing: 8) {
            Button {
                if engine.isRunning { engine.cancel(id: engine.currentJob!.id) } else { generate() }
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
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(engine.isRunning ? Color.red : theme.accentColor)
            .controlSize(.large)
            .disabled(!engine.isRunning && !canGenerate)

            if engine.queuedCount > 0 {
                Text("\(engine.queuedCount) more waiting in line")
                    .font(.system(.caption)).foregroundStyle(.secondary)
            }
        }
    }

    private var optionsCard: some View {
        CardContainer(theme: theme) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Options", systemImage: "slider.horizontal.3")
                    .font(.system(.body, weight: .semibold))
                Toggle(isOn: $settings.draftPreview) {
                    HStack(spacing: 4) {
                        Text("Quick preview")
                        HelpButton(text: "Makes a fast rough cut. When it's done you can press “Finish at full quality” — it reuses the same song, just better rendered.")
                    }
                }
                .toggleStyle(.switch).controlSize(.mini)
                Toggle(isOn: $settings.instrumental) {
                    HStack(spacing: 4) {
                        Text("Instrumental")
                        HelpButton(text: "No singing — music only.")
                    }
                }
                .toggleStyle(.switch).controlSize(.mini)
                Button { onOpenLibrary() } label: {
                    Label("Your songs…", systemImage: "music.note.list")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered).controlSize(.regular)
            }
            .padding(12)
        }
    }

    private var tipsCard: some View {
        CardContainer(theme: theme) {
            VStack(alignment: .leading, spacing: 6) {
                Label("First time here?", systemImage: "lightbulb")
                    .font(.system(.body, weight: .semibold))
                Text("Each song takes a few minutes and lives right on your Mac. Keep lyrics short (a verse, a chorus, a bridge) — shorter songs come out better.")
                    .font(.system(.caption)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
        }
    }

    // MARK: Actions

    private func generate() {
        guard let root = settings.engineRoot, let model = settings.modelDir else { return }
        engine.enqueue(settings: settings, engineRoot: root, modelDir: model)
    }

    private func shuffleStyle() {
        let all = StyleCatalog.presets
        guard !all.isEmpty else { return }
        if let idx = all.firstIndex(where: { $0.prompt == settings.style }) {
            let next = all[(idx + 1) % all.count]
            settings.style = next.prompt
            selectedVibe = next.id
        } else {
            settings.style = all[0].prompt
            selectedVibe = all[0].id
        }
    }

    private func insertTag(_ tag: String) {
        settings.lyrics += (settings.lyrics.isEmpty ? "" : "\n") + "[\(tag)]\n"
    }
}
