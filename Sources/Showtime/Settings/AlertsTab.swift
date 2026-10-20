import AppKit
import ShowtimeCore
import SwiftUI

struct AlertsTab: View {
    @ObservedObject var model: AppModel
    private let sounds = SoundPlayer.availableSounds()

    var body: some View {
        Form {
            Section("Alert Times") {
                OffsetsEditor(offsets: $model.settings.alertOffsetsMinutes)
                Toggle("Include the event's travel time", isOn: $model.settings.includeTravelTime)
                    .help("If an event has travel time in Calendar, alert that much earlier.")
            }
            Section("Snooze") {
                Stepper("Snooze 1: \(model.settings.snooze1Minutes) min", value: $model.settings.snooze1Minutes, in: 1...120)
                Stepper("Snooze 2: \(model.settings.snooze2Minutes) min", value: $model.settings.snooze2Minutes, in: 1...120)
            }
            Section("Sound") {
                HStack {
                    Picker("Sound", selection: $model.settings.soundName) {
                        Text("None").tag(String?.none)
                        ForEach(sounds, id: \.self) { Text($0).tag(String?.some($0)) }
                    }
                    Button {
                        SoundPlayer.shared.play(model.settings.soundName, volume: model.settings.soundVolume, repeating: false)
                    } label: {
                        Image(systemName: "play.circle")
                    }
                    .buttonStyle(.borderless)
                    .disabled(model.settings.soundName == nil)
                }
                Slider(value: $model.settings.soundVolume, in: 0...1) { Text("Volume") }
                Toggle("Repeat until the alert is closed", isOn: $model.settings.repeatSound)
            }
            Section("Alert Window") {
                Picker("Show on", selection: $model.settings.screenMode) {
                    Text("The screen with the mouse").tag(ScreenMode.active)
                    Text("All screens").tag(ScreenMode.all)
                    ForEach(NSScreen.screens.map(\.localizedName), id: \.self) { Text($0).tag(ScreenMode.named($0)) }
                }
                Toggle("Close alerts automatically", isOn: $model.settings.autoCloseEnabled)
                if model.settings.autoCloseEnabled {
                    Stepper("After \(model.settings.autoCloseMinutes) min", value: $model.settings.autoCloseMinutes, in: 1...120)
                }
                Stepper(String(format: "Keyboard shortcuts work after %.1f s", model.settings.shortcutDelaySeconds),
                        value: $model.settings.shortcutDelaySeconds, in: 0...5, step: 0.5)
                    .help("A short delay stops keys you were already typing from triggering the alert's buttons.")
            }
        }
        .formStyle(.grouped)
    }
}
