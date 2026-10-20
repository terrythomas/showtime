import ShowtimeCore
import SwiftUI

struct ShortcutsTab: View {
    @ObservedObject var model: AppModel
    @ObservedObject private var hotkeys = HotkeyCenter.shared

    var body: some View {
        Form {
            Section("Global Shortcuts") {
                row("Open or close the menu", .showMenu)
                row("Join the current call", .joinCall)
                row("Pause or resume alerts", .togglePause)
            }
            Section("While an Alert Is Showing") {
                LabeledContent("Join", value: "Return")
                LabeledContent("Dismiss", value: "Esc")
                LabeledContent("Snooze 1 / Snooze 2", value: "1 / 2")
                LabeledContent("Snooze until it starts", value: "S")
                LabeledContent("Show in Calendar", value: "C")
                Text("These work after the delay set in Alerts, and only when one event is showing.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private func row(_ title: String, _ action: HotkeyAction) -> some View {
        LabeledContent(title) {
            VStack(alignment: .trailing, spacing: 2) {
                ShortcutRecorder(combo: Binding(
                    get: { model.settings.hotkeys[action] },
                    set: { model.settings.hotkeys[action] = $0 }
                ))
                if hotkeys.failed.contains(action) {
                    Text("Shortcut unavailable").font(.caption).foregroundStyle(.red)
                }
            }
        }
    }
}
