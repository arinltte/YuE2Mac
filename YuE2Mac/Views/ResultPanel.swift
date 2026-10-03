//
//  ResultPanel.swift — the shared "now making / now playing" card at the
//  bottom of the writing canvas. LITE shows the friendly essentials; PRO adds
//  the artifacts row (ABC score, finish draft, export, engine log).
//

import SwiftUI
import AppKit

struct ResultPanel: View {
    @Bindable var engine: GenerationEngine
    let theme: AppTheme
    var lite: Bool
    /// PRO only: opens the ABC score editor for the shown song.
    var onEditScore: ((LibrarySong) -> Void)? = nil

    @State private var showLog = false
    @State private var exporting = false
    @State private var exportResult: String?

    private var job: GenerationEngine.Job? { engine.displayJob }
    private var settings: SettingsStore { SettingsStore.shared }

    var body: some View {
        CardContainer(theme: theme) {
            VStack(alignment: .leading, spacing: 10) {
                header

                if let job, job.state == .running {
                    runningBody(job)
                } else if let job, job.state != .queued {
                    finishedBody(job: job, song: resultSong)
                } else {
                    idleBody
                }
            }
            .padding(12)
            .frame(minHeight: 96, alignment: .topLeading)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            ZStack {
                Circle().fill(theme.accentColor.opacity(0.15)).frame(width: 30, height: 30)
                icon.font(.system(size: 14, weight: .semibold))
            }
            Text(titleText).font(.system(.title3))
            if let song = resultSong {
                if song.isDraft { ChipBadge(text: "DRAFT", tint: .orange) }
                if song.isFinished { ChipBadge(text: "FINISHED · \(song.metadata?.fullSteps ?? 32) STEPS", tint: .green) }
            }
            Spacer()
            if engine.isRunning { ProgressView().controlSize(.small) }
            if engine.queuedCount > 0 {
                Text("\(engine.queuedCount) queued")
                    .font(.system(.caption, design: .rounded)).foregroundStyle(.secondary)
            }
        }
    }

    private var icon: some View {
        switch job?.state {
        case .running: Image(systemName: "waveform").foregroundStyle(theme.accentColor)
        case .finished: Image(systemName: "checkmark").foregroundStyle(.green)
        case .failed: Image(systemName: "xmark").foregroundStyle(.red)
        case .cancelled: Image(systemName: "stop").foregroundStyle(.orange)
        default: Image(systemName: "sparkles").foregroundStyle(theme.accentColor)
        }
    }

    private var titleText: String {
        guard let job else { return lite ? "Ready to make music" : "Now playing" }
        switch job.state {
        case .running: return "Making “\(job.title)”"
        case .finished: return lite ? "Your song is ready" : "“\(job.title)”"
        case .failed: return "Something went wrong"
        case .cancelled: return "Stopped"
        case .queued: return "Waiting in queue"
        }
    }

    // MARK: Running

    private func runningBody(_ job: GenerationEngine.Job) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            StageChips(phase: job.phase, kind: job.kind, theme: theme)
            Text(processingText(job)).font(.system(.body)).foregroundStyle(.primary)
            if let p = job.progress {
                ProgressView(value: p)
                    .progressViewStyle(.linear).tint(theme.accentColor)
            } else {
                ProgressView().progressViewStyle(.linear)
            }
            if !job.detail.isEmpty {
                Text(job.detail).font(.system(.footnote, design: .monospaced)).foregroundStyle(.tertiary)
            }
        }
    }

    private func processingText(_ job: GenerationEngine.Job) -> String {
        switch job.phase {
        case .loading:    return "Loading the model (this takes a moment)…"
        case .planning:   return "Sketching the arrangement…"
        case .ar:         return "Composing the melody…"
        case .nar:        return job.kind == .finish
            ? "Refining at full quality — same song, finer detail…"
            : "Refining the sound…"
        case .decoding:   return "Rendering the audio…"
        case .writing:    return "Finalising the file…"
        default:          return "Working…"
        }
    }

    // MARK: Finished / failed / stopped

    private func finishedBody(job: GenerationEngine.Job, song: LibrarySong?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            switch job.state {
            case .failed:
                Text(job.errorMessage ?? job.detail)
                    .font(.system(.body)).foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            case .cancelled:
                Text("Stopped before finishing — nothing was kept.")
                    .font(.system(.body)).foregroundStyle(.secondary)
            default:
                if let song {
                    AudioPlayer(url: song.wav)
                    actionRow(song: song, job: job)
                    if !lite {
                        metaRow(song: song, job: job)
                        logSection
                    }
                } else {
                    idleBody
                }
            }
        }
    }

    private func actionRow(song: LibrarySong, job: GenerationEngine.Job) -> some View {
        HStack(spacing: 8) {
            if song.canFinish {
                Button { engine.enqueueFinish(of: song) } label: {
                    Label("Finish at full quality", systemImage: "wand.and.stars")
                }
                .buttonStyle(.borderedProminent).tint(theme.accentColor)
                .controlSize(.small)
                .help("Reuses this take's notes and seed; refines it with 32 steps instead of the draft's 8.")
            }
            if let abc = song.abcURL {
                Button { NSWorkspace.shared.open(abc) } label: {
                    Label("ABC score", systemImage: "doc.plaintext")
                }
                .buttonStyle(.bordered).controlSize(.small)
                if !lite, let onEditScore {
                    Button { onEditScore(song) } label: {
                        Label("Edit score", systemImage: "pencil.and.list.clipboard")
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                    .help("Open the score editor: tweak the ABC, then re-render this song.")
                }
            }
            Button {
                exporting = true
                let wav = song.wav
                Task.detached(priority: .userInitiated) {
                    let out = SongLibrary.exportM4A(from: wav)
                    await MainActor.run {
                        exporting = false
                        exportResult = out != nil ? "Exported \(out!.lastPathComponent)" : "Export failed"
                    }
                }
            } label: {
                Label(exporting ? "Exporting…" : "Export M4A", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered).controlSize(.small)
            .disabled(exporting)
            Button { NSWorkspace.shared.activateFileViewerSelecting([song.wav]) } label: {
                Label("Show in Finder", systemImage: "folder")
            }
            .buttonStyle(.bordered).controlSize(.small)
            if let result = exportResult {
                Text(result).font(.system(.caption)).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func metaRow(song: LibrarySong, job: GenerationEngine.Job) -> some View {
        HStack(spacing: 6) {
            ChipBadge(text: "seed \(job.seed)", tint: .secondary)
            ChipBadge(text: "cot \(job.cot)", tint: .secondary)
            ChipBadge(text: "\(job.steps) steps", tint: .secondary)
            if let d = song.metadata?.durationSec, d > 0 {
                ChipBadge(text: String(format: "%.1fs", d), tint: .secondary)
            }
            if let e = song.metadata?.elapsedSec, e > 0 {
                ChipBadge(text: String(format: "made in %.0fs", e), tint: .secondary)
            }
            Spacer()
            if !job.logText.isEmpty {
                Button(showLog ? "Hide log" : "Engine log") { showLog.toggle() }
                    .buttonStyle(.borderless).controlSize(.small)
                    .font(.system(.caption)).foregroundStyle(.secondary)
            }
        }
    }

    private var logSection: some View {
        Group {
            if showLog, let job {
                ScrollView {
                    Text(job.logText)
                        .font(.system(size: 10, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 120)
                .fieldLook()
            }
        }
    }

    // MARK: Idle

    @ViewBuilder
    private var idleBody: some View {
        if lite {
            (Text("Write a few words, pick a vibe, then press ")
             + Text("Generate Song").bold()
             + Text(" — your music will appear here."))
                .font(.system(.body)).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            (Text("Songs you generate stay here to replay, finish or re-render. ")
             + Text("Queue as many as you like — they run one at a time."))
                .font(.system(.body)).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Data

    /// The library entry for the displayed (finished) job, if any.
    private var resultSong: LibrarySong? {
        guard let job, job.state != .running, job.state != .queued else { return nil }
        return SongLibrary.song(inFolder: job.folder)
    }
}
