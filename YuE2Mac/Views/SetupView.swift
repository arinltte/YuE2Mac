//
//  SetupView.swift — one-time installer. Press the big button and YuE2Mac
//  downloads the YuE2 engine + a model variant from Hugging Face, builds a
//  private Python venv, and verifies everything — no folder picking required.
//

import SwiftUI

struct SetupView: View {
    @Bindable var setup: SetupManager
    @State private var variant = SystemInfo.recommendedVariant

    private var theme: AppTheme { SettingsStore.shared.theme }

    var body: some View {
        ZStack {
            AmbientThemeBackground(theme: theme).ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer()

                mark
                title

                // Spec + variant card
                CardContainer(theme: theme) {
                    VStack(spacing: 12) {
                        HStack {
                            Label("This Mac", systemImage: "cpu")
                                .font(.system(.subheadline, weight: .semibold))
                            Spacer()
                            Text("\(SystemInfo.chipName) · \(Int(SystemInfo.memoryGB)) GB RAM")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Model version").font(.system(.subheadline, weight: .semibold))
                            variantsPicker
                            Text("Recommended: **\(SystemInfo.recommendedVariant)** for this machine — \(SystemInfo.variantNote(variant))")
                                .font(.system(.caption))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Divider()

                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(theme.accentColor)
                            Text("The engine and model are fetched automatically from Hugging Face. No files to find, no folders to choose.")
                                .font(.system(.caption))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(14)
                }
                .frame(width: 440)

                statusCard
                actions

                Text("Downloads MLX · numpy · tiktoken and the ~4 GB model once, then works fully offline.")
                    .font(.system(.caption))
                    .foregroundStyle(.tertiary)

                Spacer()
            }
            .padding()
        }
        .frame(minWidth: 560, minHeight: 600)
    }

    private var variantsPicker: some View {
        ForEach(["8bit", "4bit", "bf16"], id: \.self) { v in
            Button {
                variant = v
            } label: {
                HStack {
                    Image(systemName: variant == v ? "largecircle.fill.circle" : "circle")
                        .foregroundStyle(variant == v ? theme.accentColor : Color.secondary)
                    Text(v == "8bit" ? "8-bit — balanced quality" :
                         v == "4bit" ? "4-bit — smallest" : "bf16 — highest fidelity")
                        .font(.system(.body))
                    if v == SystemInfo.recommendedVariant {
                        Text("Recommended")
                            .font(.system(.caption2, weight: .semibold))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(theme.accentColor, in: Capsule())
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var mark: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [theme.accentColor, theme.accentColor.opacity(0.5)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 84, height: 84)
            Image(systemName: "music.note.list")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(.white)
        }
        .shadow(color: theme.accentColor.opacity(0.4), radius: 22, y: 10)
    }

    private var title: some View {
        VStack(spacing: 4) {
            Text("YuE2Mac").font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text("Local AI songwriting on Apple Silicon")
                .font(.system(.subheadline))
                .foregroundStyle(.secondary)
        }
    }

    private var statusCard: some View {
        CardContainer(theme: theme) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    statusGlyph
                    Text(setup.status).font(.system(.body)).lineLimit(nil)
                    Spacer()
                }
                if setup.state == .installing {
                    ProgressView(value: setup.progress).progressViewStyle(.linear).tint(theme.accentColor)
                }
                if setup.state == .failed, let msg = setup.errorMessage {
                    Text(msg).font(.system(.caption)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
        }
        .frame(width: 420)
    }

    @ViewBuilder
    private var statusGlyph: some View {
        switch setup.state {
        case .idle: Image(systemName: "exclamationmark.circle").foregroundStyle(.orange)
        case .installing: ProgressView().controlSize(.small)
        case .ready: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .failed: Image(systemName: "xmark.octagon.fill").foregroundStyle(.red)
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button {
                SettingsStore.shared.preferredVariant = variant
                Task { await setup.install(variant: variant) }
            } label: {
                Label(setup.state == .installing ? "Setting up…" : "Download & Install",
                      systemImage: setup.state == .installing ? "hourglass" : "arrow.down.circle.fill")
                    .frame(minWidth: 160)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .tint(theme.accentColor)
            .disabled(setup.state == .installing)

            Button("Re-check") { Task { await setup.refresh() } }
                .controlSize(.large)
                .disabled(setup.state == .installing)
        }
    }
}

#Preview {
    SetupView(setup: SetupManager())
}