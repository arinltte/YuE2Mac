//
//  GenerationEngine.swift — the queue behind the studio. Runs the Python
//  engine (stock generate.py, or our bundled yue2_pro.py superset) as a child
//  process per song and turns its progress logs into per-job UI state.
//
//  Queue semantics (analysis §2.A.2/6/7): one job runs at a time, queued jobs
//  cancel instantly, a running job stops at the next step and is honestly
//  labelled "Stopped" (never "Failed"). Every song lands in its own
//  timestamped Output folder with a song.json sidecar.
//

import Foundation
import Observation

@Observable
final class GenerationEngine {
    enum Phase: Equatable {
        case idle, loading, planning, ar, nar, decoding, writing, finished, failed, cancelled
    }

    enum JobState {
        case queued, running, finished, failed, cancelled
    }

    enum JobKind: Equatable {
        case generate          // normal song from the current settings
        case rerender          // same song, edited ABC score
        case finish            // draft → full quality, reusing saved tokens
    }

    struct Job: Identifiable {
        let id = UUID()
        var kind: JobKind = .generate
        var title = "Song"
        var folder: URL
        var wavName = "song.wav"
        var engineRoot = ""
        var modelDir = ""

        // Snapshot of the request (the engine never reads live settings).
        var style = ""
        var lyrics = ""
        var cot = "full"
        var seed = 0
        var cfg: Double = 5
        var steps = 32
        var maxTokens = 4500
        var sampling = SamplingOverrides()
        var draft = false
        var abcPath: String?
        var tokensPath: String?
        var sourceFolder: String?

        // Live state.
        var state: JobState = .queued
        var phase: Phase = .idle
        var progress: Double?
        var detail = ""
        var logText = ""
        var errorMessage: String?
        var createdAt = Date()
        var startedAt: Date?
        var finishedAt: Date?

        var wavURL: URL { folder.appendingPathComponent(wavName) }
        var isRunning: Bool { state == .running }
    }

    // MARK: Observable state

    private(set) var jobs: [Job] = []
    private(set) var lastFinishedID: UUID?
    /// Bumped whenever the on-disk library changes (views re-scan).
    private(set) var libraryRevision = 0

    var currentJob: Job? { jobs.first { $0.state == .running } }
    var isRunning: Bool { currentJob != nil }
    var queuedCount: Int { jobs.filter { $0.state == .queued }.count }
    /// What the shared result panel should show: the running job, else the last result.
    var displayJob: Job? { currentJob ?? jobs.first { $0.id == lastFinishedID } }

    /// Show a past job's result in the shared panel (queue rows are clickable).
    func selectResult(_ id: UUID) {
        guard let job = jobs.first(where: { $0.id == id }),
              job.state != .running, job.state != .queued else { return }
        lastFinishedID = id
    }

    private var process: Process?
    private var runningJobID: UUID?

    deinit {
        process?.terminate()
    }

    // MARK: Pro script (bundled add-on; upstream generate.py stays untouched)

    static let proScriptName = "yue2_pro.py"

    static func deployProScript() {
        guard let bundled = Bundle.main.url(forResource: "yue2_pro", withExtension: "py") else { return }
        let dest = AppPaths.script(proScriptName)
        let current = try? String(contentsOf: dest, encoding: .utf8)
        let latest = (try? String(contentsOf: bundled, encoding: .utf8)) ?? ""
        guard current != latest else { return }
        try? FileManager.default.removeItem(at: dest)
        try? FileManager.default.copyItem(at: bundled, to: dest)
    }

    var proScriptURL: URL? {
        let url = AppPaths.script(Self.proScriptName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: Enqueueing

    /// Queue a song from the current editor settings. Draft = fast 8-step preview.
    @discardableResult
    func enqueue(settings: SettingsStore, engineRoot: String, modelDir: String) -> UUID? {
        let styleOK = !settings.effectiveStyle().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let lyricsOK = !settings.effectiveLyrics().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        guard styleOK, lyricsOK else { return nil }

        let title = Self.title(for: settings)
        var job = Job(folder: newSongFolder(named: title))
        job.kind = .generate
        job.title = title
        job.engineRoot = engineRoot
        job.modelDir = modelDir
        job.style = settings.effectiveStyle()
        job.lyrics = settings.effectiveLyrics()
        job.cot = settings.planning
        job.seed = settings.resolvedSeed() ?? Int.random(in: 0...999_999)
        job.cfg = settings.cfgScale
        job.steps = settings.draftPreview ? 8 : Int(settings.steps)
        job.maxTokens = Int(settings.maxTokens)
        job.sampling = settings.samplingOverrides
        job.draft = settings.draftPreview
        jobs.append(job)
        runNextIfNeeded()
        return job.id
    }

    /// A retake of an existing song: same everything, fresh seed.
    @discardableResult
    func enqueueVariation(of song: LibrarySong) -> UUID? {
        guard let meta = song.metadata else { return nil }
        var job = Job(folder: newSongFolder(named: song.title))
        job.kind = .generate
        job.title = song.title
        job.engineRoot = SettingsStore.shared.engineRoot ?? AppPaths.scriptsDir.path
        job.modelDir = meta.model.isEmpty ? (SettingsStore.shared.modelDir ?? "") : meta.model
        job.style = meta.style
        job.lyrics = meta.lyrics
        job.cot = meta.cot
        job.seed = Int.random(in: 0...999_999)
        job.cfg = meta.cfg
        job.steps = meta.fullSteps ?? meta.steps
        job.maxTokens = meta.maxTokens
        job.sampling = meta.sampling ?? SamplingOverrides.engineDefaults
        job.draft = false
        job.sourceFolder = song.folder?.path
        jobs.append(job)
        runNextIfNeeded()
        return job.id
    }

    /// Upgrade a draft to full quality: same tokens, same seed, 32 steps.
    @discardableResult
    func enqueueFinish(of song: LibrarySong) -> UUID? {
        guard let folder = song.folder,
              let tokens = song.draftWav?.deletingPathExtension().appendingPathExtension("tokens.json").path,
              FileManager.default.fileExists(atPath: tokens) else { return nil }
        // Never queue the same finish twice.
        if jobs.contains(where: {
            $0.kind == .finish && $0.folder == folder &&
            ($0.state == .running || $0.state == .queued)
        }) { return nil }

        var job = Job(folder: folder)
        job.kind = .finish
        job.title = song.title
        job.wavName = "song-full.wav"
        job.engineRoot = SettingsStore.shared.engineRoot ?? AppPaths.scriptsDir.path
        job.modelDir = SettingsStore.shared.modelDir ?? ""
        job.steps = 32
        job.tokensPath = tokens
        job.sourceFolder = folder.path
        jobs.append(job)
        runNextIfNeeded()
        return job.id
    }

    /// Same song, edited score: the ABC file conditions the next render.
    @discardableResult
    func enqueueRerender(of song: LibrarySong, abcText: String, newSeed: Bool) -> UUID? {
        guard let folder = song.folder, let meta = song.metadata else { return nil }
        let abcURL = folder.appendingPathComponent("score-edited.abc")
        do { try abcText.write(to: abcURL, atomically: true, encoding: .utf8) } catch { return nil }

        var job = Job(folder: newSongFolder(named: song.title))
        job.kind = .rerender
        job.title = song.title
        job.engineRoot = SettingsStore.shared.engineRoot ?? AppPaths.scriptsDir.path
        job.modelDir = meta.model.isEmpty ? (SettingsStore.shared.modelDir ?? "") : meta.model
        job.style = meta.style
        job.lyrics = meta.lyrics
        job.cot = meta.cot == "off" ? "full" : meta.cot
        job.seed = newSeed ? Int.random(in: 0...999_999) : meta.seed
        job.cfg = meta.cfg
        job.steps = meta.fullSteps ?? meta.steps
        job.maxTokens = meta.maxTokens
        job.sampling = meta.sampling ?? SamplingOverrides.engineDefaults
        job.abcPath = abcURL.path
        job.sourceFolder = folder.path
        jobs.append(job)
        runNextIfNeeded()
        return job.id
    }

    // MARK: Queue control

    /// Queued jobs vanish instantly; a running job stops at the next step.
    func cancel(id: UUID) {
        guard let idx = index(id) else { return }
        if jobs[idx].state == .queued {
            jobs.remove(at: idx)
            return
        }
        guard jobs[idx].state == .running else { return }
        jobs[idx].state = .cancelled
        process?.terminate()
        process?.interrupt()   // give Python a chance to unwind mid-loop
    }

    func remove(id: UUID) {
        guard let idx = index(id), jobs[idx].state != .running, jobs[idx].state != .queued else { return }
        jobs.remove(at: idx)
    }

    /// Drop finished/failed/stopped rows (kept around for honest history).
    func clearEnded() {
        jobs.removeAll { $0.state != .running && $0.state != .queued }
    }

    // MARK: Runner

    private func runNextIfNeeded() {
        // Keyed on the process, not currentJob: a cancelled job's process may
        // still be winding down, and two model loads at once would thrash RAM.
        guard process == nil,
              let idx = jobs.firstIndex(where: { $0.state == .queued }) else { return }
        start(idx)
    }

    private func start(_ idx: Int) {
        var job = jobs[idx]

        guard FileManager.default.fileExists(atPath: AppPaths.pythonBin.path),
              !job.engineRoot.isEmpty else {
            jobs[idx].state = .failed
            jobs[idx].errorMessage = "Missing engine files. Run Setup from Settings."
            return
        }
        let engineRoot = URL(fileURLWithPath: job.engineRoot)

        let proScript = proScriptURL
        var args: [String]
        let script: URL
        switch job.kind {
        case .generate, .rerender:
            script = proScript ?? engineRoot.appendingPathComponent("generate.py")
            args = buildGenerateArgs(job, pro: proScript != nil)
        case .finish:
            guard let pro = proScript else {
                jobs[idx].state = .failed
                jobs[idx].errorMessage = "The Pro engine add-on (yue2_pro.py) isn't installed. Reinstall the app."
                return
            }
            script = pro
            args = ["finish", "--model", job.modelDir,
                    "--project", job.tokensPath ?? "",
                    "--steps", String(job.steps),
                    "--out", job.wavURL.path]
        }
        guard FileManager.default.fileExists(atPath: script.path) else {
            jobs[idx].state = .failed
            jobs[idx].errorMessage = "Engine script not found: \(script.lastPathComponent). Run Setup from Settings."
            return
        }

        job.state = .running
        job.phase = .loading
        job.progress = 0.02
        job.detail = "Loading the model…"
        job.logText = "» python \(script.lastPathComponent) \(args.map { $0.contains(" ") ? "\"\($0)\"" : $0 }.joined(separator: " "))\n"
        job.startedAt = Date()
        jobs[idx] = job
        runningJobID = job.id

        let process = Process()
        process.executableURL = AppPaths.pythonBin
        process.arguments = [script.path] + args
        process.currentDirectoryURL = engineRoot

        var env = ProcessInfo.processInfo.environment
        env["PYTHONUNBUFFERED"] = "1"
        env["TIKTOKEN_CACHE_DIR"] = AppPaths.cacheDir.path   // keep the vocab cache out of ~/.cache
        process.environment = env

        let errPipe = Pipe()
        process.standardOutput = Pipe()
        process.standardError = errPipe
        let jobID = job.id
        process.terminationHandler = { [weak self] proc in
            Task { @MainActor [weak self] in
                self?.handleTermination(jobID: jobID, status: proc.terminationStatus)
            }
        }

        // Backpressure: drain stderr on a background thread, hop to main per line.
        errPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let self else { return }
            let text = String(decoding: data, as: UTF8.self)
            for line in text.components(separatedBy: "\n") {
                let captured = line
                Task { @MainActor in self.parse(line: captured) }
            }
        }

        self.process = process
        Task { @MainActor in
            do { try process.run() }
            catch {
                if let i = self.index(jobID) {
                    self.jobs[i].state = .failed
                    self.jobs[i].errorMessage = error.localizedDescription
                }
                self.process = nil
                self.runningJobID = nil
                self.runNextIfNeeded()
            }
        }
    }

    private func buildGenerateArgs(_ job: Job, pro: Bool) -> [String] {
        var args: [String] = []
        if pro { args.append("generate") }
        args += ["--model", job.modelDir,
                 "--style", job.style,
                 "--lyrics", job.lyrics,
                 "--cot", job.cot,
                 "--seed", String(job.seed),
                 "--cfg-scale", String(format: "%.1f", job.cfg),
                 "--steps", String(job.steps),
                 "--max-semantic-tokens", String(job.maxTokens)]
        if pro {
            let s = job.sampling
            args += ["--temperature", String(format: "%.2f", s.temperature),
                     "--top-p", String(format: "%.2f", s.topP),
                     "--top-k", String(Int(s.topK)),
                     "--rep-penalty", String(format: "%.2f", s.repetitionPenalty)]
        }
        if let abc = job.abcPath {
            args += ["--abc-file", abc]
        }
        args.append("--out")
        args.append(job.wavURL.path)
        return args
    }

    // MARK: Parsing (stderr protocol from generate.py / yue2_pro.py)

    private func parse(line raw: String) {
        let line = raw.trimmingCharacters(in: .whitespaces)
        guard !line.isEmpty, let id = runningJobID, let idx = index(id) else { return }

        if line.hasPrefix("[load]") {
            jobs[idx].phase = .loading
            jobs[idx].progress = 0.05
        } else if line.hasPrefix("[plan]") {
            jobs[idx].phase = .planning
            jobs[idx].progress = 0.08
        } else if line.hasPrefix("[semantic] prefix") {
            jobs[idx].phase = .ar
            jobs[idx].progress = 0.10
            jobs[idx].detail = "Setting up CFG…"
        } else if line.hasPrefix("[semantic]") {
            jobs[idx].phase = .ar
            // "[semantic] 200 tokens, 12.5 tok/s"
            if let m = firstMatch(#"\[semantic\] (\d+) tokens, (.*)"#, in: line),
               let tokens = Int(m[1] ?? "") {
                let maxTokens = jobs[idx].maxTokens
                let frac = maxTokens > 0 ? Double(tokens) / Double(maxTokens) : 0
                jobs[idx].progress = 0.10 + min(0.35, frac * 0.35)
                jobs[idx].detail = "\(tokens) melodic tokens · \(m[2] ?? "")"
            }
        } else if line.hasPrefix("[nar]") {
            jobs[idx].phase = .nar
            if let m = firstMatch(#"\[nar\] step (\d+)/(\d+)"#, in: line),
               let step = Int(m[1] ?? ""), let total = Int(m[2] ?? ""), total > 0 {
                jobs[idx].progress = 0.45 + 0.45 * (Double(step) / Double(total))
                jobs[idx].detail = "\(step) of \(total) refinement steps"
            }
        } else if line.hasPrefix("[vae]") {
            jobs[idx].phase = .decoding
            jobs[idx].progress = 0.92
            jobs[idx].detail = "Rendering the audio…"
        } else if line.hasPrefix("[done]") {
            jobs[idx].phase = .writing
            jobs[idx].progress = 0.98
        } else if line.hasPrefix("[error]") {
            jobs[idx].errorMessage = String(line.dropFirst("[error] ".count))
        }

        if !line.hasPrefix("[") || line.hasPrefix("[done]") || line.hasPrefix("[error]") {
            jobs[idx].logText += line + "\n"
        }
    }

    private func handleTermination(jobID: UUID, status: Int32) {
        guard let idx = index(jobID) else { return }
        process?.terminationHandler = nil
        process = nil
        runningJobID = nil
        let job = jobs[idx]

        let wavExists = FileManager.default.fileExists(atPath: job.wavURL.path)
        if status == 0 && wavExists {
            writeMetadata(for: job)
            jobs[idx].state = .finished
            jobs[idx].phase = .finished
            jobs[idx].progress = 1.0
            jobs[idx].detail = "Song complete."
            jobs[idx].finishedAt = Date()
            lastFinishedID = jobID
            libraryRevision += 1
        } else if job.state == .cancelled {
            jobs[idx].state = .cancelled
            jobs[idx].phase = .cancelled
            jobs[idx].progress = nil
            jobs[idx].detail = "Stopped by you."
            cleanupPartials(of: job)
        } else {
            jobs[idx].state = .failed
            jobs[idx].phase = .failed
            jobs[idx].progress = nil
            jobs[idx].detail = job.errorMessage ?? "Generation ended unexpectedly (exit \(status))."
            cleanupPartials(of: job)
        }
        runNextIfNeeded()
    }

    // MARK: Metadata & artifacts

    private func writeMetadata(for job: Job) {
        let duration = SongLibrary.wavDuration(job.wavURL) ?? 0
        let elapsed = job.startedAt.map { Date().timeIntervalSince($0) }

        if job.kind == .finish {
            // Update the existing sidecar rather than replacing it.
            if var meta = SongLibrary.loadMetadata(folder: job.folder) {
                meta.fullSteps = job.steps
                meta.fullDurationSec = duration
                meta.finishedAt = Date()
                SongLibrary.writeMetadata(meta, folder: job.folder)
            } else {
                // Shouldn't happen (finish always follows a successful draft), but stay honest.
                let meta = SongMetadata(
                    title: job.title, createdAt: Date(), style: "", lyrics: "", cot: "full",
                    seed: 0, cfg: 0, steps: job.steps, maxTokens: 0, sampling: nil,
                    model: job.modelDir,
                    draft: true, kind: "finish", durationSec: duration, elapsedSec: elapsed,
                    sourceFolder: job.sourceFolder,
                    fullSteps: job.steps, fullDurationSec: duration, finishedAt: Date())
                SongLibrary.writeMetadata(meta, folder: job.folder)
            }
            return
        }

        let meta = SongMetadata(
            title: job.title,
            createdAt: Date(),
            style: job.style,
            lyrics: job.lyrics,
            cot: job.cot,
            seed: job.seed,
            cfg: job.cfg,
            steps: job.steps,
            maxTokens: job.maxTokens,
            sampling: job.sampling,
            model: job.modelDir,
            draft: job.draft,
            kind: job.kind == .rerender ? "rerender" : "generate",
            durationSec: duration,
            elapsedSec: elapsed,
            sourceFolder: job.sourceFolder)
        SongLibrary.writeMetadata(meta, folder: job.folder)
    }

    /// Remove a stopped/failed job's partial artifacts; drop the folder if it
    /// was the only thing in it. Finish jobs never touch the draft's files.
    private func cleanupPartials(of job: Job) {
        let fm = FileManager.default
        let stem = job.wavName == "song-full.wav" ? "song-full" : "song"
        let folder = job.folder
        for ext in ["wav", "latents.npy", "tokens.json", "abc"] {
            let url = folder.appendingPathComponent("\(stem).\(ext)")
            if fm.fileExists(atPath: url.path) { try? fm.removeItem(at: url) }
        }
        // Remove the folder itself if nothing remains but the (now stale) sidecar.
        if let contents = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil),
           contents.allSatisfy({ $0.lastPathComponent == SongLibrary.songJSONName }) {
            try? fm.removeItem(at: folder)
        }
    }

    // MARK: Helpers

    private func index(_ id: UUID) -> Int? {
        jobs.firstIndex { $0.id == id }
    }

    /// "Indie Pop" if the style matches a catalog preset, else a few style words.
    static func title(for settings: SettingsStore) -> String {
        if let preset = StyleCatalog.preset(forPrompt: settings.style) { return preset.name }
        let words = settings.style
            .components(separatedBy: CharacterSet(charactersIn: ","))
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: " ")
            .prefix(3)
            .joined(separator: " ") ?? ""
        return words.isEmpty ? "Song" : words
    }

    private func newSongFolder(named raw: String) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let stamp = formatter.string(from: Date())

        let invalid = CharacterSet(charactersIn: "/\\:?*\"<>|")
        let safe = raw.unicodeScalars
            .map { invalid.contains($0) ? " " : Character($0) }
            .reduce(into: "") { $0.append($1) }
        var name = safe.trimmingCharacters(in: .whitespacesAndNewlines)
        name = name.components(separatedBy: " ").filter { !$0.isEmpty }.joined(separator: " ")
        if name.count > 40 { name = String(name.prefix(40)) }
        if name.isEmpty { name = "Song" }

        var candidate = AppPaths.outputDir.appendingPathComponent("\(stamp) \(name)")
        var counter = 2
        let fm = FileManager.default
        while fm.fileExists(atPath: candidate.path) {
            candidate = AppPaths.outputDir.appendingPathComponent("\(stamp) \(name) \(counter)")
            counter += 1
        }
        try? fm.createDirectory(at: candidate, withIntermediateDirectories: true)
        return candidate
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
