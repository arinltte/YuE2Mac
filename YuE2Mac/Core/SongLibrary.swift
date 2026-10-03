//
//  SongLibrary.swift — every song lives in its own timestamped folder under
//  Output/ with a song.json sidecar (style, lyrics, seed, mode, timings…).
//  The library scans those folders plus legacy loose .wav files, and provides
//  playback targets, M4A export via afconvert, and delete. (Analysis §2.A.4.)
//

import Foundation
import AppKit

/// Metadata written next to each generated song (song.json).
struct SongMetadata: Codable {
    var title: String
    var createdAt: Date
    var style: String
    var lyrics: String
    var cot: String
    var seed: Int
    var cfg: Double
    var steps: Int
    var maxTokens: Int
    var sampling: SamplingOverrides?
    var model: String
    var draft: Bool
    var kind: String            // generate | rerender | finish
    var durationSec: Double?
    var elapsedSec: Double?
    var sourceFolder: String?

    // Set when a draft is later finished at full quality.
    var fullSteps: Int?
    var fullDurationSec: Double?
    var finishedAt: Date?
}

struct LibrarySong: Identifiable {
    let id: String              // folder path (or file path for legacy wavs)
    let folder: URL?            // nil for legacy loose files
    let metadata: SongMetadata?
    let title: String
    let createdAt: Date
    let legacy: Bool

    var fullWav: URL? {
        guard let folder else { return nil }
        let url = folder.appendingPathComponent("song-full.wav")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
    var draftWav: URL? {
        guard let folder else { return nil }
        let url = folder.appendingPathComponent("song.wav")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
    var legacyWav: URL? {
        guard legacy else { return nil }
        return URL(fileURLWithPath: id)
    }
    /// The best available render: the finished version beats the draft.
    var wav: URL { fullWav ?? draftWav ?? legacyWav ?? URL(fileURLWithPath: id) }

    var isDraft: Bool { metadata?.draft == true && metadata?.fullSteps == nil }
    var isFinished: Bool { metadata?.fullSteps != nil }
    var hasTokens: Bool {
        guard let folder else { return false }
        return FileManager.default.fileExists(
            atPath: folder.appendingPathComponent("song.tokens.json").path)
    }
    var hasABC: Bool { abcURL != nil }
    var abcURL: URL? {
        guard let folder else { return nil }
        let url = folder.appendingPathComponent("song.abc")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
    /// A draft saved with semantic tokens can be finished at full quality.
    var canFinish: Bool { isDraft && hasTokens }
    /// Needs metadata (style/lyrics/seed…) to spin off variations or re-renders.
    var canVary: Bool { metadata != nil && !legacy }

    var duration: Double { SongLibrary.wavDuration(wav) ?? 0 }
    var durationText: String {
        let d = Int(duration)
        return String(format: "%d:%02d", d / 60, d % 60)
    }
}

enum SongLibrary {
    static let songJSONName = "song.json"

    // MARK: Scanning

    static func scan() -> [LibrarySong] {
        let fm = FileManager.default
        var songs: [LibrarySong] = []

        // Modern: one folder per song.
        if let folders = try? fm.contentsOfDirectory(
            at: AppPaths.outputDir, includingPropertiesForKeys: [.contentModificationDateKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]) {
            for dir in folders where dir.hasDirectoryPath {
                if let song = song(inFolder: dir) { songs.append(song) }
            }
        }

        // Legacy: loose .wav files the old app left directly in Output/.
        if let files = try? fm.contentsOfDirectory(
            at: AppPaths.outputDir, includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]) {
            for file in files where file.pathExtension.lowercased() == "wav" {
                songs.append(legacySong(file: file))
            }
        }

        return songs.sorted { $0.createdAt > $1.createdAt }
    }

    static func song(inFolder folder: URL) -> LibrarySong? {
        let fm = FileManager.default
        let wav = folder.appendingPathComponent("song.wav")
        let full = folder.appendingPathComponent("song-full.wav")
        guard fm.fileExists(atPath: wav.path) || fm.fileExists(atPath: full.path) else { return nil }

        let metadata = loadMetadata(folder: folder)
        let title = metadata?.title
            ?? folder.lastPathComponent.components(separatedBy: " ").dropFirst().joined(separator: " ")
        let created = metadata?.createdAt ?? (modificationDate(of: wav) ?? Date())

        return LibrarySong(
            id: folder.path, folder: folder, metadata: metadata,
            title: title.isEmpty ? folder.lastPathComponent : title,
            createdAt: created, legacy: false)
    }

    private static func legacySong(file: URL) -> LibrarySong {
        LibrarySong(
            id: file.path, folder: nil, metadata: nil,
            title: file.deletingPathExtension().lastPathComponent,
            createdAt: modificationDate(of: file) ?? Date(),
            legacy: true)
    }

    static func loadMetadata(folder: URL) -> SongMetadata? {
        let url = folder.appendingPathComponent(songJSONName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(SongMetadata.self, from: data)
    }

    static func writeMetadata(_ metadata: SongMetadata, folder: URL) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(metadata) {
            try? data.write(to: folder.appendingPathComponent(songJSONName), options: .atomic)
        }
    }

    // MARK: Export (native, no dependencies — afconvert ships with macOS)

    /// nonisolated: can run off the main thread (afconvert takes a few seconds).
    nonisolated static func exportM4A(from wav: URL) -> URL? {
        let out = wav.deletingPathExtension().appendingPathExtension("m4a")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/afconvert")
        process.arguments = ["-f", "m4af", "-d", "aac", "-b", "256000",
                             "-soundcheck", wav.path, out.path]
        guard (try? process.run()) != nil else { return nil }
        process.waitUntilExit()
        guard process.terminationStatus == 0, FileManager.default.fileExists(atPath: out.path) else {
            return nil
        }
        return out
    }

    // MARK: Delete

    static func delete(_ song: LibrarySong) {
        let fm = FileManager.default
        if let folder = song.folder {
            try? fm.removeItem(at: folder)
        } else {
            try? fm.removeItem(at: URL(fileURLWithPath: song.id))
        }
    }

    // MARK: WAV duration (header parse — no audio objects for a list view)

    static func wavDuration(_ url: URL) -> Double? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        guard let header = try? handle.read(upToCount: 12),
              header.count == 12,
              [UInt8](header[0...3]) == Array("RIFF".utf8) else { return nil }

        var byteRate: Int?
        while let chunk = readChunkHeader(handle) {
            if chunk.id == Array("data".utf8) {
                let rate = byteRate ?? 48000 * 2 * 2   // fallback: 48k stereo 16-bit
                return Double(chunk.size) / Double(rate)
            }
            if chunk.id == Array("fmt ".utf8) {
                guard let fmt = try? handle.read(upToCount: 16), fmt.count >= 16 else { return nil }
                let channels = Int(fmt[2]) | (Int(fmt[3]) << 8)
                let rate = Int(fmt[4]) | (Int(fmt[5]) << 8) | (Int(fmt[6]) << 16) | (Int(fmt[7]) << 24)
                let bits = Int(fmt[14]) | (Int(fmt[15]) << 8)
                if rate > 0, channels > 0, bits > 0 {
                    byteRate = rate * channels * bits / 8
                }
            } else {
                // Skip unknown chunk (+ padding to even sizes).
                try? handle.seek(toOffset: handle.offset() + UInt64(chunk.size + (chunk.size % 2)))
            }
        }
        return nil
    }

    private static func readChunkHeader(_ handle: FileHandle) -> (id: [UInt8], size: Int)? {
        guard let raw = try? handle.read(upToCount: 8), raw.count == 8 else { return nil }
        let size = Int(raw[4]) | (Int(raw[5]) << 8) | (Int(raw[6]) << 16) | (Int(raw[7]) << 24)
        return (Array(raw[0...3]), size)
    }

    private static func modificationDate(of url: URL) -> Date? {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
    }
}
