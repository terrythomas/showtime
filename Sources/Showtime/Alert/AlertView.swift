import ShowtimeCore
import SwiftUI

struct AlertView: View {
    @ObservedObject var group: AlertGroup
    let actions: AlertPanelController
    let settings: ShowtimeSettings
    @State private var customMinutes = 10
    @State private var showingCustom = false

    var body: some View {
        ZStack {
            VisualEffectBackground()
            Color.black.opacity(0.25)
            VStack(spacing: 28) {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(group.events) { e in
                            EventCard(event: e, single: group.events.count == 1, actions: actions)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .scrollIndicators(.never)
                .frame(maxHeight: 640)
                .fixedSize(horizontal: false, vertical: group.events.count == 1)
                controls
                if group.events.count == 1 { shortcutHints }
            }
            .frame(maxWidth: 820)
            .padding(48)
        }
        .ignoresSafeArea()
    }

    private var controls: some View {
        HStack(spacing: 14) {
            Menu {
                Button("\(settings.snooze1Minutes) min") { actions.snoozeAll(minutes: settings.snooze1Minutes) }
                Button("\(settings.snooze2Minutes) min") { actions.snoozeAll(minutes: settings.snooze2Minutes) }
                if let first = group.events.first, first.start > Date() {
                    Button("Until it starts") { actions.snoozeAllUntilStart() }
                }
                Divider()
                Button("Custom…") { showingCustom = true }
            } label: {
                Label("Snooze", systemImage: "zzz")
                    .frame(minWidth: 120)
            }
            .menuStyle(.button)
            .controlSize(.large)
            .fixedSize()
            .popover(isPresented: $showingCustom) {
                HStack {
                    Stepper(value: $customMinutes, in: 1...240) {
                        Text("\(customMinutes) min").monospacedDigit().frame(minWidth: 60)
                    }
                    Button("Snooze") { actions.snoozeAll(minutes: customMinutes) }
                        .keyboardShortcut(.defaultAction)
                }
                .padding()
            }

            Button {
                actions.dismissAll()
            } label: {
                Label(group.events.count > 1 ? "Dismiss All" : "Dismiss", systemImage: "xmark")
                    .frame(minWidth: 120)
            }
            .controlSize(.large)
        }
    }

    private var shortcutHints: some View {
        Text("Return Join   ·   Esc Dismiss   ·   1 / 2 Snooze \(settings.snooze1Minutes) / \(settings.snooze2Minutes) min   ·   S Until start   ·   C Calendar")
            .font(.callout)
            .foregroundStyle(.secondary)
            .opacity(group.shortcutsActive ? 1 : 0.35)
    }
}

private struct EventCard: View {
    let event: CalendarEvent
    let single: Bool
    let actions: AlertPanelController
    @State private var showNotes = false

    private var links: [MeetingLink] { MeetingLinkDetector.links(in: event) }
    private var notes: String { NotesText.plain(event.notes ?? "") }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: event.calendarColorHex))
                .frame(width: 6)
            VStack(alignment: .leading, spacing: 14) {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(TimeText.alertCountdown(start: event.start, now: context.date).uppercased())
                        .font(.system(size: 15, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(event.start <= context.date ? .orange : .accentColor)
                }
                Text(event.title.isEmpty ? "Untitled event" : event.title)
                    .font(.system(size: single ? 46 : 32, weight: .bold))
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
                details
                if !event.attendees.isEmpty { AttendeeList(attendees: event.attendees) }
                if !notes.isEmpty {
                    DisclosureGroup("View notes", isExpanded: $showNotes) {
                        ScrollView {
                            Text(notes).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 180)
                    }
                    .foregroundStyle(.secondary)
                }
                HStack(spacing: 12) {
                    if !links.isEmpty {
                        Button {
                            actions.join(event)
                        } label: {
                            Label(links.count == 1 ? "Join \(links[0].serviceName)" : "Join Call", systemImage: "video.fill")
                                .font(.system(size: 17, weight: .semibold))
                                .frame(minWidth: 180)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    Button {
                        actions.showInCalendar(event)
                    } label: {
                        Label("Show in Calendar", systemImage: "calendar")
                    }
                    .controlSize(.large)
                }
                .padding(.top, 4)
            }
            .padding(.leading, 20)
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.25), radius: 24, y: 10)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(timeRange, systemImage: "clock")
            if let location = event.location, !location.isEmpty, !location.hasPrefix("http") {
                Label(location, systemImage: "mappin.and.ellipse").lineLimit(2)
            }
            Label(event.calendarTitle, systemImage: "circle.fill")
                .labelStyle(TintedIconLabel(color: Color(hex: event.calendarColorHex)))
        }
        .font(.system(size: 16))
        .foregroundStyle(.secondary)
    }

    private var timeRange: String {
        if event.isAllDay { return "All day" }
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return "\(f.string(from: event.start)) – \(f.string(from: event.end))"
    }
}

private struct AttendeeList: View {
    let attendees: [Attendee]
    private let limit = 8

    var body: some View {
        let shown = attendees.sorted { $0.isOrganizer && !$1.isOrganizer }.prefix(limit)
        VStack(alignment: .leading, spacing: 6) {
            Text("\(attendees.count) \(attendees.count == 1 ? "participant" : "participants")")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), alignment: .leading)], alignment: .leading, spacing: 6) {
                ForEach(Array(shown.enumerated()), id: \.offset) { _, a in
                    HStack(spacing: 6) {
                        Image(systemName: icon(a.status)).foregroundStyle(color(a.status))
                        Text(a.name).lineLimit(1)
                        if a.isOrganizer { Text("organizer").font(.caption2).foregroundStyle(.secondary) }
                    }
                    .font(.system(size: 13))
                }
                if attendees.count > limit {
                    Text("+\(attendees.count - limit) more").font(.system(size: 13)).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func icon(_ s: Participation) -> String {
        switch s {
        case .accepted, .organizer: "checkmark.circle.fill"
        case .declined: "xmark.circle.fill"
        case .tentative: "questionmark.circle.fill"
        case .pending, .notInvited: "circle"
        }
    }

    private func color(_ s: Participation) -> Color {
        switch s {
        case .accepted, .organizer: .green
        case .declined: .red
        case .tentative: .orange
        case .pending, .notInvited: .secondary
        }
    }
}

private struct TintedIconLabel: LabelStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.foregroundStyle(color).font(.system(size: 9))
            configuration.title
        }
    }
}

private struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .fullScreenUI
        v.blendingMode = .behindWindow
        v.state = .active
        return v
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
