//
//  AppPaths.swift
//  YuE2Mac — central locations for the embedded Python environment, engine and model caches.
//

import Foundation

enum AppPaths {
    /// `~/Library/Application Support/YuE2Mac` — the ONLY folder the app reads
    /// during setup. We never scan Desktop/Downloads or other user folders.
    static let baseDir = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("YuE2Mac", isDirectory: true)

    /// The Python virtual environment (`.../Python/`).
    static let pythonDir = baseDir.appendingPathComponent("Python", isDirectory: true)
    static var pythonBin: URL { pythonDir.appendingPathComponent("bin/python") }

    static let cacheDir = baseDir.appendingPathComponent("Cache", isDirectory: true)

    static let outputDir = baseDir.appendingPathComponent("Output", isDirectory: true)

    /// Self-contained copy of the engine scripts (`generate.py`, `yue2_model.py`,
    /// `yue2_vae.py`) downloaded from the Hugging Face repo root.
    static let scriptsDir = baseDir.appendingPathComponent("Scripts", isDirectory: true)
    static func script(_ name: String) -> URL { scriptsDir.appendingPathComponent(name) }

    /// Self-contained download of the chosen model weights (`8bit/`, `4bit/`, `bf16/`).
    static let modelsDir = baseDir.appendingPathComponent("Models", isDirectory: true)
    static func modelDir(_ variant: String) -> URL { modelsDir.appendingPathComponent(variant, isDirectory: true) }

    /// Temporary download staging (cleaned up after each install).
    static let stagingDir = baseDir.appendingPathComponent("Staging", isDirectory: true)

    /// System Pythons we can bootstrap a venv with, best first. Prefer 3.10–3.13
    /// (MLX wheels) over the very newest (3.14+ may lack binary wheels yet).
    /// Setup is fully automatic — no user input required.
    static let pythonCandidates: [String] = [
        "/opt/homebrew/opt/python@3.13/bin/python3.13",
        "/opt/homebrew/opt/python@3.12/bin/python3.12",
        "/usr/local/opt/python@3.13/bin/python3.13",
        "/usr/local/opt/python@3.12/bin/python3.12",
        "/opt/homebrew/bin/python3",
        "/usr/local/bin/python3",
        "/usr/bin/python3",
    ].filter { FileManager.default.fileExists(atPath: $0) }
    .filter { Self.compatiblePythonVersion($0) }

    private static func compatiblePythonVersion(_ path: String) -> Bool {
        guard let version = Shell.output(path, ["--version"]) else { return false }
        // Match "Python 3.12" style strings.
        guard let match = version.range(of: #"Python (\d+)\.(\d+)"#, options: .regularExpression) else { return false }
        let digits = version[match].split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        guard digits.count >= 2 else { return false }
        return digits[0] == 3 && (digits[1] >= 10 && digits[1] <= 13)
    }

    static func prepare() throws {
        let fm = FileManager.default
        for dir in [baseDir, pythonDir, cacheDir, outputDir, scriptsDir, modelsDir] where !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }
}