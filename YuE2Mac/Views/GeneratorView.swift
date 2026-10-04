//
//  GeneratorView.swift — the studio shell. One toolbar toggle switches between
//  LITE (friendly, guided, two steps and a button) and PRO (the full toolbox:
//  queue, sampling, scores, library, artifacts). Both share the same engine
//  and the same result panel, so switching modes mid-song is safe.
//

import SwiftUI
import AppKit

struct GeneratorView: View {
    @Bindable var setup: SetupManager
    @Bindable var engine: GenerationEngine
    @Bindable private var settings = SettingsStore.shared

    @State private var showLibrary = false
    @State private var showSettings = false
    @State private var showAbout = false
    @State private var showLyricComposer = false
    @State private var editingSong: LibrarySong?

    private var theme: AppTheme { settings.theme }

    var body: some View {
        ZStack {
            AmbientThemeBackground(theme: theme).ignoresSafeArea()

            GeometryReader { g in
                Group {
                    switch settings.mode {
                    case .lite:
                        LiteModeView(engine: engine,
                                     onOpenLibrary: { showLibrary = true },
                                     onWriteLyrics: { showLyricComposer = true })
                    case .pro:
                        ProModeView(engine: engine,
                                    onOpenLibrary: { showLibrary = true },
                                    onWriteLyrics: { showLyricComposer = true },
                                    onEditScore: { song in editingSong = song })
                    }
                }
                .frame(width: g.size.width, height: g.size.height)
            }
        }
        .frame(minWidth: 1000, minHeight: 680)
        .toolbar {
            // Mode switch stays leading; every other control trails.
            ToolbarItem(placement: .navigation) {
                modeToggle
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Button { showLibrary.toggle() } label: { Image(systemName: "record.circle") }
                    .help("Your song library")
                themeMenu
                Button { showAbout.toggle() } label: { Image(systemName: "info.circle") }
                    .help("About YuE2Mac")
                    .popover(isPresented: $showAbout) { aboutContent }
                Button { showSettings = true } label: { Image(systemName: "gearshape") }
                    .help("Engine setup")
            }
        }
        .sheet(isPresented: $showLibrary) {
            LibraryView(engine: engine)
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(setup: setup)
        }
        .sheet(isPresented: $showLyricComposer) {
            LyricComposerView { lyrics in
                settings.lyrics = lyrics
            }
        }
        .sheet(item: $editingSong) { song in
            ABCEditorView(song: song, engine: engine)
        }
        .onAppear {
            GenerationEngine.deployProScript()
        }
    }

    // MARK: The one-click mode toggle

    private var modeToggle: some View {
        Picker("Mode", selection: $settings.mode) {
            Text("Lite").tag(UserMode.lite)
            Text("Pro").tag(UserMode.pro)
        }
        .pickerStyle(.segmented)
        .frame(width: 128)
        .help(settings.mode == .lite
              ? "You're in Lite mode — simple and guided. Switch to Pro for the queue, sampling controls, score editing and more."
              : "You're in Pro mode — every control unlocked. Switch to Lite for a simpler start.")
    }

    // MARK: Toolbar extras

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
            Text("Developed by arinltte · arinltte00@gmail.com")
                .font(.system(.caption2)).foregroundStyle(.secondary)

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
}
