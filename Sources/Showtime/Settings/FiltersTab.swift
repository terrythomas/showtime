import ShowtimeCore
import SwiftUI

struct FiltersTab: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Section("Which Events") {
                Toggle("Only events I've accepted", isOn: $model.settings.onlyAccepted)
                Text("Skips invitations you haven't answered or marked Maybe. Your own events still alert.")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("Only events with a video call", isOn: $model.settings.onlyWithVideo)
                Toggle("Include all-day events", isOn: $model.settings.includeAllDay)
                if model.settings.includeAllDay {
                    DatePicker("Alert for all-day events at", selection: minuteBinding($model.settings.allDayAlertMinuteOfDay),
                               displayedComponents: .hourAndMinute)
                }
            }
            WorkHoursSection(workHours: $model.settings.workHours)
            ExclusionRulesSection(rules: $model.settings.exclusionRules)
            HiddenEventsSection(model: model)
        }
        .formStyle(.grouped)
    }
}

/// Binds a "minutes after midnight" value to a DatePicker.
func minuteBinding(_ minutes: Binding<Int>) -> Binding<Date> {
    Binding {
        Calendar.current.startOfDay(for: Date()).addingTimeInterval(TimeInterval(minutes.wrappedValue * 60))
    } set: { date in
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        minutes.wrappedValue = c.hour! * 60 + c.minute!
    }
}

private struct WorkHoursSection: View {
    @Binding var workHours: WorkHours

    var body: some View {
        Section("Work Hours") {
            Toggle("Only alert during work hours", isOn: $workHours.enabled)
            if workHours.enabled {
                HStack {
                    ForEach(Array(Calendar.current.veryShortWeekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                        Toggle(symbol, isOn: weekday(index + 1)).toggleStyle(.button)
                    }
                }
                DatePicker("From", selection: minuteBinding($workHours.startMinute), displayedComponents: .hourAndMinute)
                DatePicker("To", selection: minuteBinding($workHours.endMinute), displayedComponents: .hourAndMinute)
                if workHours.isOvernight {
                    Text("Ends the next day.").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func weekday(_ day: Int) -> Binding<Bool> {
        Binding {
            workHours.weekdays.contains(day)
        } set: { on in
            if on { workHours.weekdays.insert(day) } else { workHours.weekdays.remove(day) }
        }
    }
}

private struct ExclusionRulesSection: View {
    @Binding var rules: [ExclusionRule]

    var body: some View {
        Section {
            ForEach($rules) { $rule in
                HStack {
                    Picker("", selection: $rule.field) {
                        ForEach(ExclusionRule.Field.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .labelsHidden().fixedSize()
                    Picker("", selection: $rule.comparison) {
                        Text("contains").tag(ExclusionRule.Comparison.contains)
                        Text("begins with").tag(ExclusionRule.Comparison.beginsWith)
                        Text("ends with").tag(ExclusionRule.Comparison.endsWith)
                        Text("is").tag(ExclusionRule.Comparison.equals)
                        Text("matches").tag(ExclusionRule.Comparison.matches)
                    }
                    .labelsHidden().fixedSize()
                    TextField("text", text: $rule.value)
                    Toggle("Aa", isOn: $rule.caseSensitive)
                        .toggleStyle(.button)
                        .help("Case sensitive")
                    Button {
                        rules.removeAll { $0.id == rule.id }
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    .buttonStyle(.borderless)
                }
            }
            Button("Add Rule") { rules.append(ExclusionRule()) }
        } header: {
            Text("Exclusion Rules")
        } footer: {
            Text("Events matching any rule are ignored. With “matches”, `*` stands for any text and `?` for one character.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

private struct HiddenEventsSection: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Section("Hidden Events") {
            let scopes = model.overrides.hiddenScopes
            if scopes.isEmpty {
                Text("No hidden events").foregroundStyle(.secondary)
            }
            ForEach(scopes, id: \.self) { scope in
                HStack {
                    Text(describe(scope))
                    Spacer()
                    Button("Unhide") { model.overrides.update(scope) { $0.hidden = false } }
                }
            }
        }
    }

    private func describe(_ scope: OverrideScope) -> String {
        switch scope {
        case .occurrence(let key):
            let title = model.allEvents.first { $0.key == key }?.title ?? "Unknown event"
            return "\(title) — \(key.start.formatted(date: .abbreviated, time: .shortened))"
        case .series(let id):
            let title = model.allEvents.first { $0.seriesID == id }?.title ?? "Unknown event"
            return "\(title) — all occurrences"
        }
    }
}
