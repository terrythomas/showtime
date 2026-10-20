import ShowtimeCore
import SwiftUI

struct GeneralTab: View {
    @ObservedObject var model: AppModel
    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    var body: some View {
        Form {
            Section {
                Toggle("Start Showtime when you log in", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { LaunchAtLogin.set(launchAtLogin) }
                if LaunchAtLogin.needsApproval {
                    Text("Approve Showtime in System Settings → General → Login Items.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Menu Bar") {
                Toggle("Show the next event's title", isOn: $model.settings.menuShowNextTitle)
                Group {
                    Stepper("Title length: \(model.settings.menuTitleLength) characters",
                            value: $model.settings.menuTitleLength, in: 5...60)
                    Picker("Countdown", selection: $model.settings.menuCountdown) {
                        Text("Regular (in 12 min)").tag(CountdownStyle.regular)
                        Text("Compact (12m)").tag(CountdownStyle.compact)
                        Text("Don't show").tag(CountdownStyle.none)
                    }
                    Picker("Show the next event", selection: $model.settings.menuNextEventWindowHours) {
                        Text("Any time").tag(Int?.none)
                        ForEach([1, 2, 4, 8, 12, 24], id: \.self) { Text("Within \($0) hr").tag(Int?.some($0)) }
                    }
                    Toggle("Show the current event while it's in progress", isOn: $model.settings.menuShowCurrentEvent)
                }
                .disabled(!model.settings.menuShowNextTitle)
            }
            Section("Event List") {
                Stepper("Show events for the next \(model.settings.upcomingDays) days",
                        value: $model.settings.upcomingDays, in: 1...14)
            }
        }
        .formStyle(.grouped)
    }
}
