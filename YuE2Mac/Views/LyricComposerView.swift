//
//  LyricComposerView.swift — the on-device writing room (analysis §2.D.1):
//  an idea in, a full lyric sheet out, via Apple's system model. The sheet
//  previews the result before it touches your editor.
//

import SwiftUI

struct LyricComposerView: View {
    /// Called with the generated lyric sheet when the user accepts it.
    var apply: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var idea = ""
    @State private var mood = "warm"
    @State private var output = ""
    @State private var working = false
    @State private var errorText: String?

    private let moods = ["warm", "upbeat", "melancholic", "dreamy", "epic", "playful", "nostalgic"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Write with AI", systemImage: "wand.and.stars")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("What is the song about?")
                    .font(.system(.callout, weight: .semibold))
                TextField("e.g. driving home along the coast after the last train",
                          text: $idea, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...3)
                HStack {
                    Text("Mood").font(.system(.callout)).foregroundStyle(.secondary)
                    Picker("", selection: $mood) {
                        ForEach(moods, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu).labelsHidden()
                    Spacer()
                    Button {
                        write()
                    } label: {
                        Label(working ? "Writing…" : "Write lyrics", systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(idea.trimmingCharacters(in: .whitespaces).isEmpty || working)
                }
            }

            if working {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Composing on-device…").font(.system(.caption)).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
            } else if let errorText {
                Text(errorText).font(.system(.callout)).foregroundStyle(.red)
                    .frame(maxWidth: .infinity).padding(20)
            } else if !output.isEmpty {
                ScrollView {
                    Text(output)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                .fieldLook()
                .frame(maxHeight: .infinity)

                HStack {
                    Button { write() } label: {
                        Label("Rewrite", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button {
                        apply(output)
                        dismiss()
                    } label: {
                        Label("Use these lyrics", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Text("Describe an idea above — the AI writes a short, structured lyric sheet you can edit before generating.")
                    .font(.system(.callout)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).padding(20)
            }
        }
        .padding(20)
        .frame(width: 480, height: 480)
    }

    private func write() {
        working = true
        errorText = nil
        let ideaText = idea
        let moodText = mood
        Task {
            do {
                let result = try await LyricWriter.write(idea: ideaText, mood: moodText)
                output = result
            } catch {
                errorText = error.localizedDescription
            }
            working = false
        }
    }
}
