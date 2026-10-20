import AppKit

/// Plays a macOS system sound, optionally repeating until stopped.
@MainActor
final class SoundPlayer {
    static let shared = SoundPlayer()
    private static let directory = "/System/Library/Sounds"
    private var sound: NSSound?
    private var repeatTimer: Timer?

    static func availableSounds() -> [String] {
        let files = (try? FileManager.default.contentsOfDirectory(atPath: directory)) ?? []
        return files.filter { $0.hasSuffix(".aiff") }.map { ($0 as NSString).deletingPathExtension }.sorted()
    }

    func play(_ name: String?, volume: Double, repeating: Bool) {
        stop()
        guard let name, let s = NSSound(contentsOfFile: "\(Self.directory)/\(name).aiff", byReference: true) else { return }
        s.volume = Float(volume)
        s.play()
        sound = s
        if repeating {
            repeatTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.sound?.stop()
                    self?.sound?.play()
                }
            }
        }
    }

    func stop() {
        repeatTimer?.invalidate()
        repeatTimer = nil
        sound?.stop()
        sound = nil
    }
}
