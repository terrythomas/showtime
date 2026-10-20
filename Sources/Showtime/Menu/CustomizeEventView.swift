import ShowtimeCore
import SwiftUI

/// Per-event alert times for one occurrence or the whole series.
struct CustomizeEventView: View {
    let event: CalendarEvent
    @ObservedObject var model: AppModel
    let done: () -> Void

    @State private var allOccurrences = false
    @State private var offsets: [Int] = []

    private var scope: OverrideScope { allOccurrences ? .series(event.seriesID) : .occurrence(event.key) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Alert times for “\(event.title)”").font(.headline).lineLimit(2)
            Picker("Apply to", selection: $allOccurrences) {
                Text("This occurrence").tag(false)
                Text("All occurrences").tag(true)
            }
            .pickerStyle(.segmented)
            OffsetsEditor(offsets: $offsets)
            HStack {
                Button("Use Default") {
                    model.overrides.update(scope) { $0.alertOffsetsMinutes = nil }
                    done()
                }
                Spacer()
                Button("Cancel", action: done).keyboardShortcut(.cancelAction)
                Button("Save") {
                    model.overrides.update(scope) { $0.alertOffsetsMinutes = offsets }
                    done()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 360)
        .onAppear(perform: load)
        .onChange(of: allOccurrences) { load() }
    }

    private func load() {
        offsets = model.overrides.entries[scope]?.alertOffsetsMinutes
            ?? model.overrides.resolved(for: event).alertOffsetsMinutes
            ?? model.settings.alertOffsetsMinutes
    }
}
