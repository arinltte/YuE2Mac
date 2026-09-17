//
//  SettingsSheet.swift — engine diagnostic, model variant, appearance.
//

import SwiftUI

struct SettingsSheet: View {
    let setup: SetupManager
    @Environment(\.dismiss) private var dismiss
    @State private var variant = SystemInfo.recommendedVariant

    private var settings: SettingsStore { SettingsStore.shared }
    private var theme: AppTheme { settings.theme }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings").font(.system(.title2, design: .rounded, weight: .bold))

            GroupBox(label: Label("This Mac", systemImage: "cpu")) {
                HStack {
                    Text("\(SystemInfo.chipName) · \(Int(SystemInfo.memoryGB)) GB RAM")
                        .font(.system(.body, design: .monospaced))
                    Spacer()
                    Text("Recommended model: **\(SystemInfo.recommendedVariant)**")
                        .font(.system(.caption)).foregroundStyle(.secondary)
                }
            }

            GroupBox(label: Label("Model version", systemImage: "memorychip")) {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Variant", selection: Binding(
                        get: { settings.preferredVariant.isEmpty ? SystemInfo.recommendedVariant : settings.preferredVariant },
                        set: { variant = $0 }
                    )) {
                        Text("8-bit — balanced quality").tag("8bit")
                        Text("4-bit — smallest").tag("4bit")
                        Text("bf16 — highest fidelity").tag("bf16")
                    }
                    Text(SystemInfo.variantNote(variant))
                        .font(.system(.caption)).foregroundStyle(.secondary)

                    if let root = settings.engineRoot {
                        textRow("Engine folder", root)
                    }
                    if let model = settings.modelDir {
                        textRow("In use", model)
                    }
                }
            }

            GroupBox(label: Label("Appearance", systemImage: "paintpalette")) {
                Picker("Theme", selection: Binding(
                    get: { settings.theme },
                    set: { settings.theme = $0 }
                )) {
                    ForEach(AppTheme.allCases) { t in Text(t.displayName).tag(t) }
                }
                .labelsHidden()
            }

            if setup.state == .failed, let msg = setup.errorMessage {
                Text(msg).font(.system(.caption)).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                Button("Check & Install") { Task { await setup.install(variant: variant) } }
                    .buttonStyle(.borderedProminent).tint(theme.accentColor).disabled(setup.state == .installing)
                Button("Re-check") { Task { await setup.refresh() } }.disabled(setup.state == .installing)
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 560)
        .onAppear { variant = settings.preferredVariant.isEmpty ? SystemInfo.recommendedVariant : settings.preferredVariant }
    }

    private func textRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label).font(.system(.caption2)).foregroundStyle(.secondary)
            Text(value).font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary).truncationMode(.middle).lineLimit(1)
        }
    }
}