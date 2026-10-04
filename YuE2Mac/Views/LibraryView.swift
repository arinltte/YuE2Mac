//
//  LibraryView.swift — every song YuE2Mac has made, with its metadata: draft
//  badges, seeds, durations, replay, M4A export, Finder, retakes, finish and
//  score editing. (Analysis §2.A.4/5 — ianiv-style library, native.)
//

import SwiftUI
import AppKit

struct LibraryView: View {
    @Bindable var engine: GenerationEngine
    @Environment(\.dismiss) private var dismiss

    @State private var songs: [LibrarySong] = []
    @State private var query = ""
    @State private var editingSong: LibrarySong?
    @State private var confirmingDelete: LibrarySong?
    @State private var statusNote: String?

    private var settings: SettingsStore { SettingsStore.shared }
    private var theme: AppTheme { settings.theme }

    private var filtered: [LibrarySong] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return songs }
        return songs.filter {
            $0.title.lowercased().contains(q) ||
            ($0.metadata?.style.lowercased().contains(q) ?? false) ||
            ($0.metadata?.lyrics.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Your songs", systemImage: "record.circle")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                Text("\(songs.count)").font(.system(.caption)).foregroundStyle(.secondary)
                Spacer()
                if let note = statusNote {
                    Text(note).font(.system(.caption)).foregroundStyle(.secondary)
                }
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }

            TextField("Search titles, styles, lyrics…", text: $query)
                .textFieldStyle(.roundedBorder)

            if filtered.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(filtered) { song in
                            LibraryRow(engine: engine, song: song, theme: theme,
                                       onEdit: { editingSong = song },
                                       onDelete: { confirmingDelete = song },
                                       onNote: { statusNote = $0 })
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(minWidth: 680, minHeight: 480)
        .onAppear(perform: refresh)
        .onChange(of: engine.libraryRevision) { _, _ in refresh() }
        .sheet(item: $editingSong) { song in
            ABCEditorView(song: song, engine: engine)
        }
        .confirmationDialog(
            "Delete “\(confirmingDelete?.title ?? "")”?",
            isPresented: Binding(get: { confirmingDelete != nil },
                                 set: { if !$0 { confirmingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete song", role: .destructive) {
                if let song = confirmingDelete {
                    SongLibrary.delete(song)
                    confirmingDelete = nil
                    refresh()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The song folder (audio, score, saved take) moves to the Trash.")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "music.note")
                .font(.system(size: 30)).foregroundStyle(.tertiary)
            Text(query.isEmpty ? "No songs yet — generate your first one!"
                 : "Nothing matches “\(query)”.")
                .font(.system(.callout)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func refresh() {
        songs = SongLibrary.scan()
    }
}

// MARK: - Row

private struct LibraryRow: View {
    @Bindable var engine: GenerationEngine
    let song: LibrarySong
    let theme: AppTheme
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onNote: (String) -> Void

    var body: some View {
        CardContainer(theme: theme) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(song.title).font(.system(.body, weight: .semibold)).lineLimit(1)
                        if song.isDraft { ChipBadge(text: "DRAFT", tint: .orange) }
                        if song.isFinished { ChipBadge(text: "FINISHED", tint: .green) }
                        if song.legacy { ChipBadge(text: "LEGACY", tint: .secondary) }
                    }
                    Text(subtitle).font(.system(.caption)).foregroundStyle(.secondary).lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                AudioPlayer(url: song.wav)

                Menu {
                    if song.canFinish {
                        Button {
                            engine.enqueueFinish(of: song)
                            onNote("Finishing “\(song.title)” at full quality…")
                        } label: {
                            Label("Finish at full quality", systemImage: "wand.and.stars")
                        }
                    }
                    if song.hasABC {
                        Button(action: onEdit) {
                            Label("Edit score & re-render", systemImage: "pencil.and.list.clipboard")
                        }
                        if let abc = song.abcURL {
                            Divider()
                            Button { NSWorkspace.shared.open(abc) } label: {
                                Label("Open ABC file", systemImage: "doc.plaintext")
                            }
                        }
                    }
                    if song.canVary {
                        Button {
                            engine.enqueueVariation(of: song)
                            onNote("Queued a new take of “\(song.title)”…")
                        } label: {
                            Label("New take (new seed)", systemImage: "arrow.counterclockwise.circle")
                        }
                    }
                    Divider()
                    Button {
                        let wav = song.wav
                        Task.detached(priority: .userInitiated) {
                            let out = SongLibrary.exportM4A(from: wav)
                            await MainActor.run {
                                if let out {
                                    onNote("Exported \(out.lastPathComponent)")
                                } else {
                                    onNote("Export failed")
                                }
                            }
                        }
                    } label: {
                        Label("Export M4A (256 kbps)", systemImage: "square.and.arrow.up")
                    }
                    Button { NSWorkspace.shared.activateFileViewerSelecting([song.wav]) } label: {
                        Label("Show in Finder", systemImage: "folder")
                    }
                    Divider()
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete…", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 15))
                }
                .menuStyle(.borderlessButton)
                .frame(width: 26)
            }
            .padding(10)
        }
    }

    private var subtitle: String {
        var parts: [String] = [
            song.createdAt.formatted(date: .abbreviated, time: .shortened),
            song.durationText,
        ]
        if let meta = song.metadata {
            parts.append("seed \(meta.seed)")
            parts.append("cot \(meta.cot)")
            if song.isFinished, let steps = meta.fullSteps {
                parts.append("\(steps) steps")
            } else {
                parts.append("\(meta.steps) steps")
            }
        }
        return parts.joined(separator: " · ")
    }
}
