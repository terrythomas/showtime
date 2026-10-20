import AppKit
import Carbon.HIToolbox
import ShowtimeCore
import SwiftUI

/// Click, then press a key combination with ⌘, ⌃ or ⌥. Esc cancels.
struct ShortcutRecorder: View {
    @Binding var combo: KeyCombo?
    @State private var recording = false
    @State private var monitor: Any?

    var body: some View {
        HStack(spacing: 4) {
            Button {
                recording ? stop() : start()
            } label: {
                Text(recording ? "Type shortcut…" : (combo?.displayString ?? "Record Shortcut"))
                    .frame(minWidth: 110)
            }
            if combo != nil {
                Button {
                    combo = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.borderless)
                .help("Clear shortcut")
            }
        }
        .onDisappear(perform: stop)
    }

    private func start() {
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let isEscape = event.keyCode == UInt16(kVK_Escape)
            let hasModifier = !event.modifierFlags.intersection([.command, .control, .option]).isEmpty
            let captured = hasModifier ? KeyCombo(event: event) : nil
            MainActor.assumeIsolated {
                if isEscape {
                    stop()
                } else if let captured {
                    combo = captured
                    stop()
                }
            }
            return nil
        }
    }

    private func stop() {
        recording = false
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}
