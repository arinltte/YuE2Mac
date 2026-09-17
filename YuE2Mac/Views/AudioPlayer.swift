//
//  AudioPlayer.swift — a compact AVAudioPlayer wrapper to audition the result.
//

import SwiftUI
import AVFoundation

struct AudioPlayer: View {
    let url: URL
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var current: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var observer: Timer?

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
        .onAppear(perform: prepare)
        .onDisappear(perform: stopAndCleanup)
    }

    private func prepare() {
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return }
        p.prepareToPlay()
        player = p
        duration = p.duration
        observer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            guard let p = self.player else { return }
            Task { @MainActor in
                self.current = p.currentTime
                if !p.isPlaying { self.isPlaying = false }
            }
        }
    }

    private func toggle() {
        guard let p = player else { return }
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