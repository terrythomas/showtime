import AppKit
import ShowtimeCore
import SwiftUI

struct MenuView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var calendar: CalendarSource
    let openSettings: () -> Void
    let closeMenu: () -> Void

    @State private var showAll = false
    @State private var customizing: CalendarEvent?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            content(now: context.date)
        }
        .frame(width: 360)
        .sheet(item: $customizing) { e in
            CustomizeEventView(event: e, model: model) { customizing = nil }
        }
    }

    private func content(now: Date) -> some View {
        let events = model.events
        let ongoing = events.filter { $0.start <= now && now < $0.end }
        let upcoming = events.filter { $0.start > now && (showAll || Calendar.current.isDate($0.start, inSameDayAs: now)) }

        return VStack(alignment: .leading, spacing: 0) {
            banners(now: now)
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    if !ongoing.isEmpty {
                        sectionHeader("Ongoing")
                        ForEach(ongoing) { row($0, now: now) }
                    }
                    HStack {
                        sectionHeader("Upcoming")
                        Spacer()
                        Picker("", selection: $showAll) {
                            Text("Today").tag(false)
                            Text("\(model.settings.upcomingDays) days").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .fixedSize()
                        .padding(.trailing, 12)
                    }
                    if upcoming.isEmpty {
                        Text("No upcoming events")
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                    }
                    ForEach(upcoming) { row($0, now: now) }
                }
                .padding(.vertical, 6)
            }
            .frame(maxHeight: 420)
            .fixedSize(horizontal: false, vertical: true)
            Divider()
            footer(now: now, ongoing: ongoing)
        }
    }

    // MARK: Banners

    @ViewBuilder
    private func banners(now: Date) -> some View {
        switch accessBanner(for: calendar.authorization) {
        case .none:
            EmptyView()
        case .requestAccess:
            banner("Showtime needs access to your calendars.", button: "Allow Access") {
                Task { await calendar.requestAccess() }
            }
        case .openSystemSettings:
            banner("Calendar access is off. Showtime can't see your meetings.", button: "Open System Settings") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!)
            }
        case .restricted:
            banner("Calendar access is restricted on this Mac (Screen Time or a management profile).", button: nil) {}
        }
        if model.isPaused, let until = model.pausedUntil {
            banner(until == .distantFuture ? "Alerts are paused." : "Alerts are paused until \(until.formatted(date: .omitted, time: .shortened)).",
                   button: "Resume") { model.resume() }
        }
        if !model.settings.workHours.allows(now, calendar: .current) {
            banner("Outside work hours. No alerts until they start.", button: nil) {}
        }
    }

    private func banner(_ text: String, button: String?, action: @escaping () -> Void) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange)
            Text(text).font(.callout).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            if let button { Button(button, action: action).controlSize(.small) }
        }
        .padding(10)
        .background(.orange.opacity(0.12))
    }

    // MARK: Rows

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 2)
    }

    private func row(_ e: CalendarEvent, now: Date) -> some View {
        let hasLink = !MeetingLinkDetector.links(in: e).isEmpty
        let hidden = model.isHidden(e)
        let outsideHours = model.alertsBlockedByWorkHours(e)
        return Button {
            closeMenu()
            if !LinkOpener.join(e, model: model) { model.calendar.showInCalendar(e) }
        } label: {
            HStack(spacing: 8) {
                Circle().fill(Color(hex: e.calendarColorHex)).frame(width: 8, height: 8)
                Text(timeLabel(e, now: now))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 76, alignment: .leading)
                VStack(alignment: .leading, spacing: 1) {
                    Text(e.title.isEmpty ? "Untitled" : e.title).lineLimit(1)
                    if hidden {
                        Text("No alert (hidden)").font(.caption2).foregroundStyle(.secondary)
                    } else if outsideHours {
                        Text("No alert (outside work hours)").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if hasLink { Image(systemName: "video.fill").foregroundStyle(.secondary) }
            }
            .opacity(hidden ? 0.5 : 1)
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu { contextMenu(e, hasLink: hasLink, hidden: hidden) }
    }

    @ViewBuilder
    private func contextMenu(_ e: CalendarEvent, hasLink: Bool, hidden: Bool) -> some View {
        if hasLink {
            Button("Join Now") { closeMenu(); LinkOpener.join(e, model: model) }
        }
        Button("Show in Calendar") { closeMenu(); model.calendar.showInCalendar(e) }
        Divider()
        if hidden {
            Button("Unhide") {
                model.overrides.update(.occurrence(e.key)) { $0.hidden = false }
                model.overrides.update(.series(e.seriesID)) { $0.hidden = false }
            }
        } else {
            Menu("Don't Alert Me") {
                Button("This Occurrence") { model.overrides.update(.occurrence(e.key)) { $0.hidden = true } }
                Button("All Occurrences") { model.overrides.update(.series(e.seriesID)) { $0.hidden = true } }
            }
        }
        Button("Customize Alert Times…") { customizing = e }
    }

    private func timeLabel(_ e: CalendarEvent, now: Date) -> String {
        if e.isAllDay { return "all day" }
        if Calendar.current.isDate(e.start, inSameDayAs: now) {
            return e.start.formatted(date: .omitted, time: .shortened)
        }
        return e.start.formatted(.dateTime.weekday(.abbreviated).hour().minute())
    }

    // MARK: Footer

    private func footer(now: Date, ongoing: [CalendarEvent]) -> some View {
        HStack {
            Menu {
                Button("15 minutes") { model.pause(until: now.addingTimeInterval(15 * 60)) }
                Button("30 minutes") { model.pause(until: now.addingTimeInterval(30 * 60)) }
                Button("1 hour") { model.pause(until: now.addingTimeInterval(3600)) }
                Button("Until the end of this event") {
                    if let end = ongoing.map(\.end).max() { model.pause(until: end) }
                }
                .disabled(ongoing.isEmpty)
                Button("Rest of today") {
                    model.pause(until: Calendar.current.startOfDay(for: now).addingTimeInterval(86400))
                }
                Button("Indefinitely") { model.pause(until: .distantFuture) }
            } label: {
                Label(model.isPaused ? "Paused" : "Pause Alerts", systemImage: "pause.circle")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            if model.isPaused {
                Button("Resume") { model.resume() }.controlSize(.small)
            }
            Spacer()
            Button {
                closeMenu()
                openSettings()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .help("Settings…")
            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help("Quit Showtime")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
