//
//  AudioPlayer.swift — a compact inline player. The AVAudioPlayer is created
//  lazily on the first play tap (a library list shouldn't preload every wav),
//  and the total time comes from a cheap WAV-header parse.
//

import SwiftUI
import AVFoundation

struct AudioPlayer: View {
    let url: URL
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var current: TimeInterval = 0
    @State private var observer: Timer?

    private var duration: TimeInterval { SongLibrary.wavDuration(url) ?? 0 }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                toggle()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)

            Slider(value: $current, in: 0...max(duration, 0.001)) { editing in
                if !editing { seek() }
            }
            .disabled(duration == 0)

            Text(timeString(current))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 44)
        }
        .onDisappear(perform: stopAndCleanup)
    }

    private func ensurePlayer() -> AVAudioPlayer? {
        if let p = player { return p }
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return nil }
        p.prepareToPlay()
        player = p
        observer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            guard let p = self.player else { return }
            Task { @MainActor in
                self.current = p.currentTime
                if !p.isPlaying { self.isPlaying = false }
            }
        }
        return p
    }

    private func toggle() {
        guard let p = ensurePlayer() else { return }
        if p.isPlaying {
            p.pause()
            isPlaying = false
        } else {
            p.play()
            isPlaying = true
        }
    }

    private func seek() {
        player?.currentTime = current
    }

    private func stopAndCleanup() {
        observer?.invalidate()
        observer = nil
        player?.stop()
        player = nil
    }

    private func timeString(_ t: TimeInterval) -> String {
        String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }
}
