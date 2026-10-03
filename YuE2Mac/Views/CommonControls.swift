//
//  CommonControls.swift — small reusable controls shared by LITE and PRO views.
//

import SwiftUI

/// An inline “?” that explains on hover and shows a popover on click.
struct HelpButton: View {
    let text: String
    @State private var show = false

    var body: some View {
        Button {
            show.toggle()
        } label: {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 12)).foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help(text)
        .popover(isPresented: $show, arrowEdge: .bottom) {
            Text(text)
                .font(.system(.caption))
                .foregroundStyle(.primary)
                .padding(12).frame(width: 230)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// A label on the left with an optional help icon, and its control pinned right.
func alignRow<Content: View>(title: String, help: String? = nil,
                             @ViewBuilder _ content: () -> Content) -> some View {
    HStack {
        HStack(spacing: 4) {
            Text(title).font(.system(.callout)).foregroundStyle(.secondary)
            if let help { HelpButton(text: help) }
        }
        Spacer()
        content()
    }
}

/// A titled slider row with live value readout.
func labeledSlider(_ title: String,
                   _ bound: Binding<Double>,
                   _ range: ClosedRange<Double>,
                   whole: Bool,
                   theme: AppTheme,
                   step: Double = 1,
                   help: String = "") -> some View {
    VStack(alignment: .leading, spacing: 3) {
        HStack {
            HStack(spacing: 4) {
                Text(title).font(.system(.callout)).foregroundStyle(.secondary)
                HelpButton(text: help)
            }
            Spacer()
            Text(formatValue(bound.wrappedValue, whole: whole))
                .font(.system(.subheadline, design: .monospaced)).foregroundStyle(.primary)
        }
        Slider(value: bound, in: range, step: step).tint(theme.accentColor)
    }
}

func formatValue(_ v: Double, whole: Bool) -> String {
    whole ? "\(Int(v))" : String(format: "%.2g", v)
}

// MARK: - Stage chips (Load → Plan → Compose → Refine → Render → Save)

/// The six pipeline stages as a chip row; done stages get a checkmark.
struct StageChips: View {
    let phase: GenerationEngine.Phase
    let kind: GenerationEngine.JobKind?
    let theme: AppTheme

    private struct Stage {
        let label: String
        let phase: GenerationEngine.Phase
    }

    private var stages: [Stage] {
        var all: [Stage] = [
            Stage(label: "Load", phase: .loading),
            Stage(label: "Plan", phase: .planning),
            Stage(label: "Compose", phase: .ar),
            Stage(label: "Refine", phase: .nar),
            Stage(label: "Render", phase: .decoding),
        ]
        // Plan/Compose are skipped when finishing from saved tokens — hide them.
        if kind == .finish {
            all.removeAll { $0.phase == .planning || $0.phase == .ar }
        }
        all.append(Stage(label: "Save", phase: .writing))
        return all
    }

    private func stageState(_ stage: Stage) -> Int {
        // 0 = done, 1 = current, 2 = pending
        let order: (GenerationEngine.Phase) -> Int = {
            switch $0 {
            case .loading: return 0
            case .planning: return 1
            case .ar: return 2
            case .nar: return 3
            case .decoding: return 4
            case .writing, .finished: return 5
            default: return -1
            }
        }
        let current = order(phase)
        let this = order(stage.phase)
        if phase == .finished { return 0 }
        guard current >= 0 else { return 2 }
        return this < current ? 0 : (this == current ? 1 : 2)
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(stages, id: \.label) { stage in
                let state = stageState(stage)
                HStack(spacing: 3) {
                    Image(systemName: state == 0 ? "checkmark.circle.fill"
                          : state == 1 ? "circle.circle.fill" : "circle.dotted")
                        .font(.system(size: 10, weight: .semibold))
                    Text(stage.label).font(.system(size: 10, weight: .medium))
                }
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(
                    state == 1 ? theme.accentColor.opacity(0.22)
                    : Color.white.opacity(state == 0 ? 0.06 : 0.03),
                    in: Capsule()
                )
                .foregroundStyle(state == 2 ? Color.secondary.opacity(0.6) : state == 1 ? theme.accentColor : Color.secondary)
            }
        }
    }
}

// MARK: - Small badges

struct ChipBadge: View {
    let text: String
    var tint: Color = .secondary

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold, design: .rounded))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(tint.opacity(0.18), in: Capsule())
            .foregroundStyle(tint)
            .help(text)
    }
}

extension View {
    func fieldLook(fill: Color = Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.05),
                   border: Color = Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.10)) -> some View {
        self
            .padding(10)
            .background(fill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(border, lineWidth: 1))
    }
}
