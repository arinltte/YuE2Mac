//
//  GenerationEngine.swift — runs `generate.py` as a child process and turns its
//  progress logs into UI state. Cancellation terminates the process cleanly.
//

import Foundation
import Observation

@Observable
final class GenerationEngine {
    enum Phase: Equatable {
        case idle, preparing, planning, ar, nar, decoding, writing, finished, failed, cancelled
    }

    var phase: Phase = .idle
    var progressMessage = ""
    /// nil = indeterminate; a value = a fraction for a determinate bar.
    var progress: Double?
    var logText = ""

    var outputURL: URL?
    private var currentOut: URL?
    private var process: Process?
    private var runnerTask: Task<Void, Never>?

    var isRunning: Bool {
        switch phase {
        case .preparing, .planning, .ar, .nar, .decoding: return true
        default: return false
        }
    }

    var phaseTitle: String {
        switch phase {
        case .idle: return "Ready"
        case .preparing: return "Preparing prompts"
        case .planning: return "Planning the arrangement"
        case .ar: return "Composing the core melody"
        case .nar: return "Refining acoustics & timbre"
        case .decoding: return "Rendering final audio"
        case .writing: return "Writing file"
        case .finished: return "Complete"
        case .failed: return "Failed"
        case .cancelled: return "Stopped"
        }
    }

    var detailLine: String {
        switch phase {
        case .ar, .nar, .decoding: return progressMessage
        default: return ""
        }
    }

    func generate(settings: SettingsStore, engineRoot: String, modelDir: String, output: URL) {
        guard !isRunning else { return }
        let python = AppPaths.pythonBin.path
        let script = URL(fileURLWithPath: engineRoot).appendingPathComponent("generate.py").path
        guard FileManager.default.fileExists(atPath: python),
              FileManager.default.fileExists(atPath: script) else {
            phase = .failed
            progressMessage = "Missing engine files. Run Setup from Settings."
            return
        }

        var args: [String] = [script, "--model", modelDir,
                              "--style", settings.effectiveStyle(),
                              "--lyrics", settings.effectiveLyrics(),
                              "--cot", settings.planning,
                              "--cfg-scale", String(format: "%.1f", settings.cfgScale),
                              "--steps", String(Int(settings.steps)),
                              "--max-semantic-tokens", String(Int(settings.maxTokens)),
                              "--out", output.path]
        if let seed = settings.resolvedSeed() {
            args += ["--seed", String(seed)]
        }

        phase = .preparing
        progress = 0.02
        progressMessage = ""
        logText = "» python \(args.map(quote).joined(separator: " "))\n"
        outputURL = output
        currentOut = output

        let process = Process()
        process.executableURL = URL(fileURLWithPath: python)
        process.arguments = args
        process.currentDirectoryURL = URL(fileURLWithPath: engineRoot)

        var env = ProcessInfo.processInfo.environment
        env["PYTHONUNBUFFERED"] = "1"
        env["TIKTOKEN_CACHE_DIR"] = AppPaths.cacheDir.path   // keep the vocab cache out of ~/.cache
        process.environment = env

        let errPipe = Pipe()
        process.standardOutput = Pipe()
        process.standardError = errPipe
        process.terminationHandler = { [weak self] proc in
            Task { @MainActor [weak self] in
                self?.handleTermination(status: proc.terminationStatus)
            }
        }

        errPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let self else { return }
            let text = String(decoding: data, as: UTF8.self)
            for line in text.components(separatedBy: "\n") {
                Task { @MainActor in self.parse(line: line) }
            }
        }

        self.process = process
        runnerTask = Task { @MainActor in
            do {
                try process.run()
            } catch {
                self.phase = .failed
                self.progressMessage = error.localizedDescription
                self.process = nil
            }
        }
    }

    func cancel() {
        guard isRunning else { return }
        phase = .cancelled
        process?.terminate()
        process?.interrupt()   // give Python a chance to unwind (midpoint loop)
        // `handleTermination` tidies the partial files.
    }

    // MARK: - Parsing

    private func parse(line: String) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if trimmed.hasPrefix("[plan]") {
            phase = .planning
            progress = 0.05
        } else if trimmed.hasPrefix("[semantic] prefix") {
            phase = .ar
            progress = 0.08
            progressMessage = "Setting up CFG…"
        } else if trimmed.hasPrefix("[semantic]") {
            // "[semantic] N tokens, X tok/s"
            phase = .ar
            let comps = trimmed.components(separatedBy: ",")
            if let first = comps.first?.dropFirst(" [semantic] ".count),
               let tokens = Int(String(first).trimmingCharacters(in: CharacterSet.decimalDigits.inverted)) {
                let maxTokens = Int(SettingsStore.shared.maxTokens)
                let frac = maxTokens > 0 ? CGFloat(tokens) / CGFloat(maxTokens) : 0
                progress = 0.08 + min(0.37 - 0.08, frac * 0.37)
                progressMessage = "\(tokens) melodic tokens so far"
                if comps.count > 1 {
                    let speed = comps[1].trimmingCharacters(in: .whitespaces)
                    progressMessage += " · \(speed)"
                }
            }
        } else if trimmed.hasPrefix("[nar]") {
            // "[nar] step i/n"
            phase = .nar
            if let stepMatch = firstMatch("[nar] step (\\d+)/(\\d+)", in: trimmed),
               let step = Int(stepMatch[1]!), let total = Int(stepMatch[2]!), total > 0 {
                progress = 0.45 + 0.45 * (CGFloat(step) / CGFloat(total))
                progressMessage = "\(step) of \(total) refinement steps"
            } else if trimmed.contains("frames") {
                progressMessage = trimmed
            }
        } else if trimmed.hasPrefix("[vae]") {
            phase = .decoding
            progress = 0.9
            progressMessage = "Decoding the audio waveform…"
        } else if trimmed.hasPrefix("[done]") {
            // "[done] /path/file.wav 24.0s in 48s"
            phase = .writing
            progress = 0.98
            progressMessage = "Finishing up…"
        }

        if !trimmed.hasPrefix("[") || trimmed.hasPrefix("[done]") {
            logText += trimmed + "\n"
        }
    }

    private func handleTermination(status: Int32) {
        process?.terminationHandler = nil
        process = nil

        switch phase {
        case .decoding, .writing:
            // The engine wrote the .wav and exited. Drop the large intermediate.
            removeLatentsFile()
            phase = .finished
            progress = 1.0
            progressMessage = "Song complete."
        case .preparing, .planning, .ar, .nar, .cancelled:
            // Distinguish a user's Stop from an actual failure.
            if phase == .cancelled {
                progressMessage = "Stopped by user."
                phase = .cancelled
            } else {
                progressMessage = "Generation ended unexpectedly (exit \(status))."
                phase = .failed
            }
            progress = nil
            cleanupPartialFiles()
        default:
            phase = .failed
            progress = nil
            progressMessage = "Generation ended unexpectedly (exit \(status))."
            cleanupPartialFiles()
        }
    }

    private func cleanupPartialFiles() {
        guard let out = currentOut else { return }
        let fm = FileManager.default
        for url in [out, out.deletingPathExtension().appendingPathExtension("latents.npy"),
                    out.deletingPathExtension().appendingPathExtension("abc")] {
            if fm.fileExists(atPath: url.path) {
                try? fm.removeItem(at: url)
            }
        }
        currentOut = nil
    }

    private func removeLatentsFile() {
        guard let out = currentOut else { return }
        let latents = out.deletingPathExtension().appendingPathExtension("latents.npy")
        if FileManager.default.fileExists(atPath: latents.path) {
            try? FileManager.default.removeItem(at: latents)
        }
    }

    // MARK: - Helpers

    private func quote(_ arg: String) -> String {
        "\"\(arg)\""
    }

    private func firstMatch(_ pattern: String, in text: String) -> [String?]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range) else { return nil }
        return (0..<match.numberOfRanges).map { i in
            Range(match.range(at: i), in: text).map { String(text[$0]) }
        }
    }
}