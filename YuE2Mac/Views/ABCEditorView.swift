//
//  ABCEditorView.swift — the white-box interface to YuE2 (analysis §2.B).
//  Every song saves its ABC score; here you can tweak it, make the song
//  instrumental (official Vocal→Ins recipe), and re-render with the same
//  seed and settings — plus a light structural check before you commit.
//

import SwiftUI

struct ABCEditorView: View {
    let song: LibrarySong
    @Bindable var engine: GenerationEngine
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var originalText = ""
    @State private var newSeed = false
    @State private var loading = true

    private var settings: SettingsStore { SettingsStore.shared }
    private var theme: AppTheme { settings.theme }

    private var summary: ABCTools.Summary { ABCTools.summary(text) }
    private var structureWarning: String? {
        ABCTools.changeWarning(original: originalText, edited: text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Score editor", systemImage: "pencil.and.list.clipboard")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Spacer()
                Text(song.title).font(.system(.callout)).foregroundStyle(.secondary)
                Button("Done") { dismiss() }.keyboardShortcut(.cancelAction)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .font(.system(size: 12, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .opacity(loading ? 0.3 : 1)
            }
            .fieldLook()
            .frame(maxHeight: .infinity)

            // Light validation + invariant hint.
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: summary.isPlausible ? "checkmark.seal" : "exclamationmark.triangle")
                        .foregroundStyle(summary.isPlausible ? Color.green : Color.orange)
                    Text("\(summary.notes) notes · \(summary.bars) bar marks · voices: \(summary.voices.joined(separator: ", "))")
                        .font(.system(.caption, design: .monospaced))
                    Spacer()
                }
                ForEach(summary.problems, id: \.self) { problem in
                    Text("⚠︎ \(problem)").font(.system(.caption)).foregroundStyle(.orange)
                }
                if let warning = structureWarning {
                    Text("⚠︎ \(warning)").font(.system(.caption)).foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 10) {
                Button {
                    text = ABCTools.makeInstrumental(text)
                } label: {
                    Label("Make instrumental", systemImage: "speaker.slash")
                }
                .buttonStyle(.bordered)
                .disabled(ABCTools.isInstrumental(text))
                .help("Moves every sung note to the instrument voice (the official YuE2 recipe) — much more reliable than asking in the style prompt.")

                Toggle(isOn: $newSeed) {
                    Text("New seed").help("Off: the same seed as the original take (closest match). On: a fresh take of your edited score.")
                }
                .toggleStyle(.checkbox).controlSize(.small)

                Spacer()

                Button("Re-render with this score") {
                    if engine.enqueueRerender(of: song, abcText: text, newSeed: newSeed) != nil {
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.accentColor)
                .disabled(!summary.isPlausible)
            }
        }
        .padding(20)
        .frame(minWidth: 640, minHeight: 520)
        .onAppear(perform: load)
    }

    private func load() {
        if let abc = song.abcURL, let content = try? String(contentsOf: abc, encoding: .utf8) {
            text = content
            originalText = content
        } else {
            text = "// No ABC score was saved for this song."
        }
        loading = false
    }
}
