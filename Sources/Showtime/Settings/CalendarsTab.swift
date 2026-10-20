import SwiftUI

struct CalendarsTab: View {
    @ObservedObject var model: AppModel
    @ObservedObject var calendar: CalendarSource

    var body: some View {
        Form {
            if calendar.calendarGroups.isEmpty {
                Text("No calendars found. Add your accounts in Calendar.app, and allow Showtime to access your calendars.")
                    .foregroundStyle(.secondary)
            }
            ForEach(calendar.calendarGroups) { group in
                Section(group.sourceTitle) {
                    ForEach(group.calendars) { cal in
                        Toggle(isOn: binding(for: cal.id)) {
                            HStack {
                                Circle().fill(Color(hex: cal.colorHex)).frame(width: 10, height: 10)
                                Text(cal.title)
                            }
                        }
                    }
                }
            }
            Section {
                Text("Keep your work calendar added in Calendar.app (System Settings → Internet Accounts). Showtime reads whatever Calendar.app shows.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private func binding(for id: String) -> Binding<Bool> {
        Binding {
            !model.settings.disabledCalendarIDs.contains(id)
        } set: { on in
            if on { model.settings.disabledCalendarIDs.remove(id) } else { model.settings.disabledCalendarIDs.insert(id) }
        }
    }
}
