//
//  LibraryView.swift — every song YuE2Mac has made, with its metadata: draft
//  badges, seeds, durations, replay, M4A export, Finder, retakes, parameter
//  reuse, batched version queues, finish and score editing. Shown as a
//  resizable right-hand pane (Analysis §2.A.4/5 — ianiv-style library, native).
//

import SwiftUI
import AppKit

enum RatingFilter: String, CaseIterable {
    case all = "All"
    case liked = "Liked"
    case disliked = "Disliked"
}

struct LibraryView: View {
    @Bindable var engine: GenerationEngine
    /// Hides the pane (the library is a right-hand pane, not a sheet — there's
    /// nothing to dismiss). The toolbar button toggles the same state.
    var onClose: () -> Void

    @State private var songs: [LibrarySong] = []
    @State private var query = ""
    @State private var filter: RatingFilter = .all
    @State private var editingSong: LibrarySong?
    @State private var confirmingDelete: LibrarySong?
    /// IDs of the songs selected for bulk actions (checkboxes / Select All).
    @State private var selectedIDs: Set<String> = []
    @State private var confirmingBulkDelete = false
    @State private var statusNote: String?
    @State private var showPlaylist = false
    @ObservedObject private var playlist = PlaylistManager.shared

    private var settings: SettingsStore { SettingsStore.shared }
    private var theme: AppTheme { settings.theme }

    private var filtered: [LibrarySong] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        return songs.filter { song in
            // Apply rating filter first.
            switch filter {
            case .all:
                break
            case .liked:
                guard song.liked else { return false }
            case .disliked:
                guard song.disliked else { return false }
            }
            // Then apply text search.
            if !q.isEmpty {
                return song.title.lowercased().contains(q) ||
                    (song.metadata?.style.lowercased().contains(q) ?? false) ||
                    (song.metadata?.lyrics.lowercased().contains(q) ?? false)
            }
            return true
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
                Button(action: { showPlaylist.toggle() }) {
                    Label("Playlist", systemImage: "music.note.list")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help(showPlaylist ? "Hide playlist" : "Show playlist")
                Button("Done") { onClose() }
            }

            // Rating filter buttons + select-all (operates on what's visible,
            // so e.g. "Disliked" + Select All selects exactly the disliked songs).
            HStack(spacing: 8) {
                ForEach(RatingFilter.allCases, id: \.self) { f in
                    let isActive = filter == f
                    Button(f.rawValue) {
                        filter = f
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(isActive ? theme.accentColor : nil)
                }
                Spacer()
                let visibleIDs = Set(filtered.map(\.id))
                let allVisibleSelected = !visibleIDs.isEmpty && visibleIDs.isSubset(of: selectedIDs)
                Button(allVisibleSelected ? "Deselect All" : "Select All") {
                    if allVisibleSelected {
                        selectedIDs.removeAll()
                    } else {
                        selectedIDs.formUnion(visibleIDs)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(filtered.isEmpty)
                .help(allVisibleSelected ? "Clear the selection"
                                         : "Select every song shown by the current filter and search")
            }

            TextField("Search titles, styles, lyrics…", text: $query)
                .textFieldStyle(.roundedBorder)

            // Bulk actions for the current selection.
            if !selectedIDs.isEmpty {
                HStack(spacing: 8) {
                    Text("\(selectedIDs.count) selected")
                        .font(.system(.caption, weight: .semibold))
                    Button {
                        bulkAddToPlaylist()
                    } label: {
                        Label("Add to Playlist", systemImage: "plus.circle")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    Button(role: .destructive) {
                        confirmingBulkDelete = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    Spacer()
                }
            }

            if filtered.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(filtered) { song in
                            LibraryRow(engine: engine, song: song, theme: theme,
                                       isSelected: selectedIDs.contains(song.id),
                                       onToggleSelect: { toggleSelection(song) },
                                       onEdit: { editingSong = song },
                                       onDelete: { confirmingDelete = song },
                                       onReuse: { reuseParameters(from: song) },
                                       onQueueVersions: { queueVersions(of: song, count: $0) },
                                       onNote: { statusNote = $0 },
                                       onToggleLike: {
                                           SongLibrary.toggleLike(song)
                                           refresh()
                                       },
                                       onToggleDislike: {
                                           SongLibrary.toggleDislike(song)
                                           refresh()
                                       },
                                       onAddToPlaylist: {
                                           playlist.add(song.wav)
                                           // If the playlist isn't driving playback, start this
                                           // track from its spot in the queue.
                                           if playlist.currentIndex == -1 {
                                               if let idx = playlist.tracks.firstIndex(of: song.wav) {
                                                   playlist.currentIndex = idx
                                               }
                                               PlaybackCoordinator.shared.play(song.wav)
                                           }
                                       })
                        }
                    }
                }
            }

            // Playlist panel (bottom half when shown).
            if showPlaylist {
                Divider().padding(.vertical, 8)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Now Playing", systemImage: "play.circle.fill")
                            .font(.system(.headline, design: .rounded))
                        Spacer()
                        if playlist.tracks.count > 0 {
                            Button("Clear") { playlist.clear() }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        }
                    }

                    if playlist.tracks.isEmpty {
                        Text("Add songs with the + button on each row.")
                            .font(.system(.caption))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(20)
                    } else {
                        ScrollView {
                            VStack(spacing: 4) {
                                ForEach(Array(playlist.tracks.enumerated()), id: \.element) { index, url in
                                    PlaylistRow(
                                        index: index,
                                        url: url,
                                        isCurrent: playlist.currentIndex == index,
                                        count: playlist.tracks.count,
                                        onPlay: {
                                            // Double-click: start here and continue sequentially.
                                            if let target = playlist.play(from: index) {
                                                PlaybackCoordinator.shared.play(target)
                                            }
                                        },
                                        onRemove: { playlist.remove(url) },
                                        onMoveUp: {
                                            if index > 0 {
                                                playlist.move(from: index, to: index - 1)
                                            }
                                        },
                                        onMoveDown: {
                                            if index < playlist.tracks.count - 1 {
                                                playlist.move(from: index, to: index + 1)
                                            }
                                        }
                                    )
                                }
                            }
                        }

                        PlaylistControls()
                    }
                }
                .frame(maxHeight: 260)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            refresh()
            // Set up auto-play next track when current one finishes. Only
            // advance if the finished track is actually the playlist's current
            // one — a song played from elsewhere (e.g. the result panel) must
            // not drag the queue along.
            PlaybackCoordinator.shared.onTrackFinished = { finishedUrl in
                guard let current = playlist.currentTrack, current == finishedUrl else { return }
                if let nextUrl = playlist.playNext() {
                    PlaybackCoordinator.shared.play(nextUrl)
                }
            }
        }
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
                    playlist.remove(song.wav)   // don't leave a dead entry in the queue
                    selectedIDs.remove(song.id)
                    confirmingDelete = nil
                    refresh()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The song folder (audio, score, saved take) moves to the Trash.")
        }
        .confirmationDialog(
            "Delete \(selectedIDs.count) songs?",
            isPresented: $confirmingBulkDelete,
            titleVisibility: .visible
        ) {
            Button("Delete songs", role: .destructive) { deleteSelected() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The song folders (audio, score, saved takes) move to the Trash.")
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
        // Drop selection entries for songs that no longer exist.
        selectedIDs.formIntersection(Set(songs.map(\.id)))
    }

    // MARK: - Bulk selection actions

    @MainActor
    private func toggleSelection(_ song: LibrarySong) {
        if selectedIDs.contains(song.id) {
            selectedIDs.remove(song.id)
        } else {
            selectedIDs.insert(song.id)
        }
    }

    /// The selected songs, in library order (newest first).
    private var selectedSongs: [LibrarySong] {
        songs.filter { selectedIDs.contains($0.id) }
    }

    @MainActor
    private func bulkAddToPlaylist() {
        let targets = selectedSongs
        guard !targets.isEmpty else { return }
        var added = 0
        var already = 0
        for song in targets {
            if playlist.tracks.contains(song.wav) {
                already += 1
            } else {
                playlist.add(song.wav)
                added += 1
            }
        }
        statusNote = already > 0
            ? "Added \(added) to playlist (\(already) already there)"
            : "Added \(targets.count) song\(targets.count == 1 ? "" : "s") to playlist"
    }

    /// "Reuse": load the song's full parameter set into the editor so it can
    /// be tweaked and re-generated.
    @MainActor
    private func reuseParameters(from song: LibrarySong) {
        guard let meta = song.metadata else { return }
        SettingsStore.shared.loadSongParameters(meta, draft: song.isDraft)
        statusNote = "Loaded “\(song.title)” into the editor — tweak it and generate"
    }

    /// Queue `count` versions of a song: same parameters, fresh seed each.
    @MainActor
    private func queueVersions(of song: LibrarySong, count: Int) {
        let wasBusy = engine.isRunning
        let queued = engine.enqueueVersions(of: song, count: count)
        guard queued > 0 else {
            statusNote = "Can't queue versions — this song has no saved parameters"
            return
        }
        statusNote = wasBusy
            ? "Queued \(queued) versions of “\(song.title)” — they'll start after the current song finishes"
            : "Queued \(queued) versions of “\(song.title)” — starting now, fresh seed each"
    }

    @MainActor
    private func deleteSelected() {
        let targets = selectedSongs
        guard !targets.isEmpty else { return }
        for song in targets {
            SongLibrary.delete(song)
            playlist.remove(song.wav)   // don't leave dead entries in the queue
        }
        selectedIDs.subtract(targets.map(\.id))
        confirmingBulkDelete = false
        statusNote = "Deleted \(targets.count) song\(targets.count == 1 ? "" : "s")"
        refresh()
    }
}

// MARK: - Row

private struct LibraryRow: View {
    @Bindable var engine: GenerationEngine
    let song: LibrarySong
    let theme: AppTheme
    let isSelected: Bool
    var onToggleSelect: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onReuse: () -> Void
    var onQueueVersions: (Int) -> Void
    var onNote: (String) -> Void
    var onToggleLike: () -> Void
    var onToggleDislike: () -> Void
    var onAddToPlaylist: () -> Void

    var body: some View {
        CardContainer(theme: theme) {
            HStack(alignment: .center, spacing: 12) {
                Toggle(isOn: Binding(get: { isSelected }, set: { _ in onToggleSelect() })) {
                    EmptyView()
                }
                .toggleStyle(.checkbox)
                .help("Select for bulk actions")
                .accessibilityLabel("Select \(song.title)")

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

                // Like / Dislike buttons.
                Button(action: onToggleLike) {
                    Image(systemName: song.liked ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .foregroundStyle(song.liked ? theme.accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help("Like this song")

                Button(action: onToggleDislike) {
                    Image(systemName: song.disliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        .foregroundStyle(song.disliked ? theme.accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help("Dislike this song")

                // Add to playlist button.
                Button(action: onAddToPlaylist) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(theme.accentColor)
                }
                .buttonStyle(.plain)
                .help("Add to playlist")

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
                            Button {
                                // openFile(_:withApplication:) is deprecated (macOS 11+).
                                if let textEdit = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.TextEdit") {
                                    let config = NSWorkspace.OpenConfiguration()
                                    NSWorkspace.shared.open([abc], withApplicationAt: textEdit, configuration: config) { _, _ in }
                                } else {
                                    NSWorkspace.shared.open(abc)
                                }
                            } label: {
                                Label("Open ABC file", systemImage: "doc.plaintext")
                            }
                        }
                    }
                    if song.canVary {
                        Button(action: onReuse) {
                            Label("Reuse parameters", systemImage: "arrow.uturn.left")
                        }
                        .help("Load this song's style, lyrics and settings back into the editor")
                        Button {
                            let wasBusy = engine.isRunning
                            engine.enqueueVariation(of: song)
                            onNote(wasBusy
                                ? "Queued a new take of “\(song.title)” — it'll start after the current song finishes"
                                : "Queued a new take of “\(song.title)” — starting now")
                        } label: {
                            Label("New take (new seed)", systemImage: "arrow.counterclockwise.circle")
                        }
                        Menu {
                            ForEach(2...GenerationEngine.maxVersions, id: \.self) { n in
                                Button("\(n) versions") { onQueueVersions(n) }
                            }
                        } label: {
                            Label("Queue multiple versions…", systemImage: "rectangle.stack")
                        }
                        .help("Same parameters, a fresh random seed per version — all queued at once")
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

// MARK: - Playlist Row

private struct PlaylistRow: View {
    let index: Int
    let url: URL
    let isCurrent: Bool
    /// Total number of tracks (drives the move-down button's enabled state).
    let count: Int
    var onPlay: () -> Void
    var onRemove: () -> Void
    var onMoveUp: () -> Void
    var onMoveDown: () -> Void

    private var title: String {
        // The playlist stores wav file URLs; the metadata sidecar lives in the
        // song's folder, so resolve it from the containing directory.
        if let meta = SongLibrary.loadMetadata(folder: url.deletingLastPathComponent()) {
            return meta.title
        }
        return url.lastPathComponent
    }

    var body: some View {
        HStack(spacing: 8) {
            Text("\(index + 1)")
                .font(.system(.caption, weight: .bold))
                .frame(width: 20, alignment: .center)
                .foregroundStyle(isCurrent ? Color.accentColor : .secondary)

            if isCurrent {
                Image(systemName: "play.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.accentColor)
            }

            Text(title)
                .font(.system(.caption))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onMoveUp) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 10))
            }
            .buttonStyle(.plain)
            .disabled(index == 0)

            Button(action: onMoveDown) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
            .buttonStyle(.plain)
            .disabled(index >= count - 1)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(6)
        .background(isCurrent ? Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        // Double-click starts playback from this track (and continues on).
        .onTapGesture(count: 2, perform: onPlay)
    }
}

// MARK: - Playlist Controls

/// Transport controls for the playlist queue (previous / play-pause / next).
/// Only active while the shared player actually has the playlist's current
/// track loaded — a song played from elsewhere (e.g. the result panel) leaves
/// them disabled rather than hijacking playback.
private struct PlaylistControls: View {
    @ObservedObject var playlist = PlaylistManager.shared
    @ObservedObject var coordinator = PlaybackCoordinator.shared

    /// True when the shared player has the playlist's current track loaded.
    private var controlsPlaylist: Bool {
        guard let track = playlist.currentTrack else { return false }
        return coordinator.url == track
    }

    private var isPlaying: Bool { controlsPlaylist && coordinator.isPlaying }

    var body: some View {
        HStack(spacing: 20) {
            Button(action: playPrevious) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 16, weight: .semibold))
            }
            .buttonStyle(.plain)
            .disabled(!controlsPlaylist || playlist.currentIndex <= 0)
            .help("Previous track")

            Button(action: togglePlayPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!controlsPlaylist)
            .help(isPlaying ? "Pause" : "Play")

            Button(action: playNext) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 16, weight: .semibold))
            }
            .buttonStyle(.plain)
            .disabled(!controlsPlaylist || playlist.currentIndex >= playlist.tracks.count - 1)
            .help("Next track")
        }
    }

    private func togglePlayPause() {
        guard let track = playlist.currentTrack, coordinator.url == track else { return }
        if coordinator.isPlaying {
            coordinator.pause()
        } else {
            coordinator.play(track)
        }
    }

    private func playPrevious() {
        guard let url = playlist.play(from: playlist.currentIndex - 1) else { return }
        coordinator.play(url)
    }

    private func playNext() {
        guard let url = playlist.play(from: playlist.currentIndex + 1) else { return }
        coordinator.play(url)
    }
}
