import ShowtimeCore
import SwiftUI

/// Edits a list of "minutes before start" alert times.
struct OffsetsEditor: View {
    @Binding var offsets: [Int]
    @State private var newMinutes = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(AlertOffsets.sorted(offsets), id: \.self) { minutes in
                HStack {
                    Image(systemName: "bell")
                    Text(AlertOffsets.describe(minutes))
                    Spacer()
                    Button {
                        offsets.removeAll { $0 == minutes }
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    .buttonStyle(.borderless)
                    .disabled(!AlertOffsets.canRemove(from: offsets))
                    .help("Remove this alert")
                }
            }
            HStack {
                Stepper(value: $newMinutes, in: AlertOffsets.range, step: 1) {
                    TextField("Minutes", value: $newMinutes, format: .number)
                        .frame(width: 56)
                        .multilineTextAlignment(.trailing)
                }
                Text("min before")
                Button("Add") { offsets.append(newMinutes) }
                    .disabled(AlertOffsets.problem(adding: newMinutes, to: offsets) != nil)
            }
            if let problem = AlertOffsets.problem(adding: newMinutes, to: offsets) {
                Text(problem).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
