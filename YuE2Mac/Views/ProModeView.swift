//
//  ProModeView.swift — the full studio. Everything LITE hides lives here:
//  the queue with live stage chips, model & planning, quality, advanced
//  sampling, length, seed, plus the shared result panel with artifacts.
//

import SwiftUI

struct ProModeView: View {
    @Bindable var engine: GenerationEngine
    var onOpenLibrary: () -> Void
    var onWriteLyrics: () -> Void
    var onEditScore: (LibrarySong) -> Void

    @Bindable private var settings = SettingsStore.shared
    @State private var showAdvanced = false

    private var theme: AppTheme { settings.theme }

    private var modelOptions: [String] {
        guard let root = settings.engineRoot else { return [] }
        return SetupManager.availableModels(engineRoot: root)
    }

    private var canGenerate: Bool {
        !settings.effectiveStyle().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !settings.effectiveLyrics().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        GeometryReader { g in
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    writingCard
                    ResultPanel(engine: engine, theme: theme, lite: false, onEditScore: onEditScore)
                        .frame(maxHeight: 200)
                }
                .padding(20)
                .frame(width: g.size.width * 0.60, height: g.size.height)

                Divider().opacity(0.6)

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        generateCard
                        if !engine.jobs.isEmpty { queueCard }
                        modelCard
                        qualityCard
                        samplingCard
                        lengthCard
                        seedCard
                    }
                    .padding(16)
                }
                .frame(width: g.size.width * 0.40, height: g.size.height)
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
            Button { onOpenLibrary() } label: { Label("Library", systemImage: "record.circle") }
                .buttonStyle(.bordered).controlSize(.small)
        }
    }

    private var modelSummary: String {
        let name = settings.modelDir.flatMap { URL(fileURLWithPath: $0).lastPathComponent } ?? "no model"
        return "\(SystemInfo.chipName) · \(name)"
    }

    // MARK: Writing canvas

    private var writingCard: some View {
        CardContainer(theme: theme) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Lyrics & Style", systemImage: "square.and.pencil")
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                    Spacer()
                    if LyricWriter.isAvailable {
                        Button(action: onWriteLyrics) {
                            Label("Write with AI", systemImage: "wand.and.stars")
                        }
                        .buttonStyle(.borderless).controlSize(.small)
                        .foregroundStyle(theme.accentColor)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label("Style prompt", systemImage: "slider.horizontal.3")
                            .font(.system(.body, weight: .semibold))
                        Spacer()
                        Menu {
                            ForEach(StyleCatalog.categories, id: \.self) { category in
                                Menu(category) {
                                    ForEach(StyleCatalog.presets(in: category)) { preset in
                                        Button("\(preset.emoji) \(preset.name)") {
                                            settings.style = preset.prompt
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label("Browse presets", systemImage: "books.vertical")
                        }
                        .menuStyle(.borderlessButton).controlSize(.small).fixedSize()
                        .help("The curated style catalog")

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
                        .fieldLook()
                }

                Divider()

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

                ZStack(alignment: .bottomTrailing) {
                    TextEditor(text: $settings.lyrics)
                        .font(.system(.body))
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 150, maxHeight: .infinity)
                        .fieldLook()
                    Text("\(settings.lyrics.count) characters")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.tertiary).padding(.trailing, 14).padding(.bottom, 8)
                }
            }
            .padding(12)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: Generate

    private var generateCard: some View {
        VStack(spacing: 8) {
            Button {
                generate()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text(engine.isRunning ? "Add to queue" : "Generate Song")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accentColor)
            .controlSize(.large)
            .disabled(!canGenerate)

            if engine.isRunning, let job = engine.currentJob {
                Button(role: .destructive) {
                    engine.cancel(id: job.id)
                } label: {
                    Label("Stop “\(job.title)”", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered).controlSize(.regular)
            }
            if engine.queuedCount > 0 {
                Text("\(engine.queuedCount) in queue — one song renders at a time")
                    .font(.system(.caption)).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Queue

    private var queueCard: some View {
        CardContainer(theme: theme) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Queue", systemImage: "list.number")
                        .font(.system(.body, weight: .semibold))
                    Spacer()
                    Button("Clear ended") { engine.clearEnded() }
                        .buttonStyle(.borderless).controlSize(.small)
                        .font(.system(.caption)).foregroundStyle(.secondary)
                }
                ForEach(engine.jobs) { job in
                    QueueRow(engine: engine, job: job, theme: theme)
                }
            }
            .padding(12)
        }
    }

    // MARK: Model & planning

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
                alignRow(title: "Planning (COT)", help: "Simulate an outline first? Full writes a chord chart, Melody keeps the tune only, Off goes straight to audio (fastest).") {
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

    // MARK: Quality

    private var qualityCard: some View {
        CardContainer(theme: theme) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Quality", systemImage: "waveform.path").font(.system(.body, weight: .semibold))
                Toggle(isOn: $settings.draftPreview) {
                    HStack(spacing: 4) {
                        Text("Draft preview (8 steps)")
                        HelpButton(text: "Fast rough cut. Press “Finish at full quality” afterwards — it reuses this take's notes and seed, only refining better.")
                    }
                }
                .toggleStyle(.switch).controlSize(.mini)
                labeledSlider("Refinement steps", $settings.steps, 10...100, whole: true, theme: theme,
                              help: settings.draftPreview
                              ? "Drafts always use 8 steps."
                              : "How many times the audio is refined. 32 is a good default.")
                    .disabled(settings.draftPreview)
                    .opacity(settings.draftPreview ? 0.5 : 1)
                labeledSlider("CFG — obedience", $settings.cfgScale, 1...15, whole: false, theme: theme,
                              help: "Higher follows your style more strictly; lower is more creative. 5 is a good default.")
                    .disabled(settings.draftPreview)
                    .opacity(settings.draftPreview ? 0.5 : 1)
            }
            .padding(12)
        }
    }

    // MARK: Advanced sampling

    private var samplingCard: some View {
        CardContainer(theme: theme) {
            VStack(alignment: .leading, spacing: 10) {
                DisclosureGroup(isExpanded: $showAdvanced) {
                    VStack(alignment: .leading, spacing: 10) {
                        labeledSlider("Temperature", $settings.temperature, 0.1...1.5, whole: false, theme: theme, step: 0.05,
                                      help: "Higher = wilder note choices. 1.0 is the model default.")
                        labeledSlider("Top-p", $settings.topP, 0.5...1.0, whole: false, theme: theme, step: 0.01,
                                      help: "Nucleus sampling cut-off. 0.95 is the model default.")
                        labeledSlider("Top-k", $settings.topK, 1...500, whole: true, theme: theme,
                                      help: "Only the k most likely notes are considered. 100 is the model default.")
                        labeledSlider("Repetition penalty", $settings.repPenalty, 1.0...1.6, whole: false, theme: theme, step: 0.05,
                                      help: "Above 1 discourages the model from replaying a memorized song. 1.2 is the model default.")
                        HStack {
                            Spacer()
                            Button("Reset to defaults") { settings.resetSampling() }
                                .buttonStyle(.borderless).controlSize(.small)
                                .disabled(settings.samplingOverrides.isDefault)
                        }
                    }
                    .padding(.top, 4)
                } label: {
                    HStack {
                        Label("Advanced sampling", systemImage: "dial.max")
                            .font(.system(.body, weight: .semibold))
                        if !settings.samplingOverrides.isDefault {
                            ChipBadge(text: "custom", tint: .orange)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold)).foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(showAdvanced ? 90 : 0))
                    }
                }
            }
            .padding(12)
        }
    }

    // MARK: Length & seed

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
                alignRow(title: "Seed", help: "Same lyrics + same seed = the same song. Leave blank for a random one each time.") {
                    TextField("Random", text: $settings.seed)
                        .textFieldStyle(.plain)
                        .font(.system(.body, design: .monospaced))
                        .multilineTextAlignment(.trailing)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color(red: 1, green: 1, blue: 1, opacity: 0.05),
                                    in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .frame(width: 110)
                }
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
            settings.style = all[(idx + 1) % all.count].prompt
        } else {
            settings.style = all[0].prompt
        }
    }

    private func insertTag(_ tag: String) {
        settings.lyrics += (settings.lyrics.isEmpty ? "" : "\n") + "[\(tag)]\n"
    }
}

// MARK: - Queue row

private struct QueueRow: View {
    @Bindable var engine: GenerationEngine
    let job: GenerationEngine.Job
    let theme: AppTheme

    private var stateIcon: (String, Color) {
        switch job.state {
        case .queued: return ("clock", .secondary)
        case .running: return ("waveform", theme.accentColor)
        case .finished: return ("checkmark.circle.fill", .green)
        case .failed: return ("xmark.circle.fill", .red)
        case .cancelled: return ("stop.circle.fill", .orange)
        }
    }

    private var stateText: String {
        switch job.state {
        case .queued: return "waiting"
        case .running: return "running"
        case .finished: return "done"
        case .failed: return "failed"
        case .cancelled: return "stopped"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            let icon = stateIcon
            Image(systemName: icon.0).font(.system(size: 12, weight: .semibold)).foregroundStyle(icon.1)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(job.title).font(.system(.callout, weight: .medium)).lineLimit(1)
                    if job.kind == .finish { ChipBadge(text: "FINISH", tint: .green) }
                    if job.kind == .rerender { ChipBadge(text: "RE-RENDER", tint: .purple) }
                    if job.draft && job.state != .finished { ChipBadge(text: "DRAFT", tint: .orange) }
                }
                if job.state == .running {
                    StageChips(phase: job.phase, kind: job.kind, theme: theme)
                } else if job.state == .failed, let err = job.errorMessage {
                    Text(err).font(.system(.caption2)).foregroundStyle(.red).lineLimit(1)
                } else {
                    Text(stateText).font(.system(.caption2)).foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if job.state == .running, let p = job.progress {
                ProgressView(value: p)
                    .progressViewStyle(.circular)
                    .frame(width: 34)
                    .tint(theme.accentColor)
            }

            switch job.state {
            case .running, .queued:
                Button {
                    engine.cancel(id: job.id)
                } label: {
                    Image(systemName: job.state == .running ? "stop.circle" : "xmark.circle")
                        .font(.system(size: 13))
                }
                .buttonStyle(.borderless).foregroundStyle(.secondary)
                .help(job.state == .running ? "Stop this song" : "Remove from queue")
            default:
                Button {
                    engine.remove(id: job.id)
                } label: {
                    Image(systemName: "xmark.circle").font(.system(size: 13))
                }
                .buttonStyle(.borderless).foregroundStyle(.tertiary)
                .help("Remove from list")
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            if job.state == .finished || job.state == .failed || job.state == .cancelled {
                engine.selectResult(job.id)
            }
        }
    }
}
