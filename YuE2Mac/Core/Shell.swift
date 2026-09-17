//
//  Shell.swift — runs a child process and streams output; used by SetupManager.
//

import Foundation

enum Shell {
    /// Run a command, streaming lines to `log`, and `await` its exit status.
    static func run(
        executable: String,
        arguments: [String],
        currentDirectory: URL? = nil,
        environment: [String: String] = [:],
        log: @escaping (String) -> Void = { _ in }
    ) async throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        if let dir = currentDirectory { process.currentDirectoryURL = dir }

        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        for (k, v) in environment { env[k] = v }
        process.environment = env

        let out = Pipe()
        process.standardOutput = out
        process.standardError = out   // merge so the setup log sees errors too

        return try await withCheckedThrowingContinuation { continuation in
            out.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty, let text = String(data: data, encoding: .utf8) {
                    log(text)
                }
            }
            process.terminationHandler = { _ in
                out.fileHandleForReading.readabilityHandler = nil
                continuation.resume(returning: process.terminationStatus)
            }
            do { try process.run() }
            catch { continuation.resume(throwing: error) }
        }
    }

    /// Run a short command and return trimmed stdout (or nil on failure).
    static func output(_ executable: String, _ arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do { try process.run() } catch { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func fileExists(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
}