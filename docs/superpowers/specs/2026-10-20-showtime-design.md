# Showtime — Design

Date: 2026-10-20
Status: draft, awaiting approval

## Intent

Terry uses **In Your Face** (blue banana software, Mac App Store) for full-screen meeting alerts. On their work laptop it isn't usable:

- The work calendar is locked down, so the app's Google/Microsoft sign-in can't be used.
- After the free trial, the app stops alerting without a subscription (observed in the shipped binary: log line *"Not showing event because free trial has ended"*).

Showtime is a free, local-only replacement. It reads the calendars already present in macOS Calendar (via EventKit, which includes Exchange/Google/iCloud accounts added to Calendar.app) and puts an unmissable full-screen alert in front of the user before each meeting, with a one-click Join for the video call.

Success: on the work laptop, Terry never misses a meeting start, can join the call from the alert in one click, and never has to sign in to anything.

## Reference behavior

Features were taken from In Your Face v3.28.1's shipped UI strings and defaults (`/Applications/In Your Face.app/Contents/Resources`). Showtime reimplements the behavior. **No code, sounds, themes, images, or text files are copied from that app.** Meeting-link patterns are written fresh from the services' public URL formats.

Reference defaults worth matching: alert 1 minute before start; snooze presets 1 and 5 minutes; auto-close after 15 minutes when enabled; upcoming list covers 7 days.

## Goals (v1)

### Full-screen alert
- At each alert time, show a borderless full-screen window above all other windows, including other apps' full-screen spaces, on: the active screen (default) / all screens / one chosen screen.
- Contents: event title, start–end time, relative countdown that updates live ("starts in 1 min" / "started 2 min ago"), calendar name and colour, location, notes (collapsed, expandable), attendees with RSVP status (accepted/declined/tentative/pending), organizer marked.
- Buttons: **Join** (shown only if a video link was found), **Snooze** (preset 1, preset 2, custom minutes, until event start), **Dismiss**, **Show in Calendar**.
- If two events alert at the same time, show them together in one alert, each with its own buttons, rather than stacking separate windows.
- Sound when the alert appears: any macOS system sound (`/System/Library/Sounds`) or none; optional repeat until the alert is acted on; volume setting.
- Optional auto-close after N minutes (default off, 15 when enabled).
- Keyboard shortcuts while the alert is up: Join, Snooze 1, Snooze 2, Snooze until start, Dismiss, Show in Calendar. A short configurable delay (default 1 s) before these become active, so you don't trigger them by accident while typing.

### Join / video links
- Find meeting links in the event URL, location, and notes. Support at least: Zoom (incl. zoomgov, custom vanity subdomains), Google Meet, Microsoft Teams (incl. teams.live.com and .us gov), Webex, GoToMeeting, Jitsi, Whereby, BlueJeans, Chime, Slack huddles, Around, Gather, Dialpad, Vonage, Zoho, Livekit, Proton Meet, Lifesize, RingCentral, Skype. The list lives in one data table, so adding a service is a one-line change.
- If more than one distinct link is found, ask which to open, with a "remember for this event" option.
- Open Zoom/Teams links in their native apps where installed (zoommtg://, msteams:); otherwise the default browser.
- Right-click an event in the menu → **Join now**, any time.

### Alert schedule
- One or more alert times per event, set globally (e.g. 10 min and 1 min before). 0–24 h before start, unique values, up to 10. A plain list editor is enough; no timeline UI.
- Option to include the event's travel time if Calendar provides it. EventKit doesn't expose travel time publicly; see Open questions.

### Menu bar
- Icon plus, optionally, the next event's title (truncated to a set length) and a countdown ("in 12m"). Options: show next event only within the next N hours or today, show the current event while it's in progress.
- Dropdown: Ongoing events, Upcoming events (today / next N days toggle). Each row shows time, title, calendar colour and a join indicator. Row context menu: Join now, Show in Calendar, Hide this event, Customize alert time.
- Pause alerts: 15 min, 30 min, 1 h, until end of current event, today, indefinitely; resume. While paused, the menu bar icon changes so it's obvious.
- Settings…, Quit.

### Event selection
- Choose active calendars (grouped by account, as in Calendar.app).
- Filters: only accepted events (ignore pending/tentative), only events with a video link, include/skip all-day events, ignore events the user declined (always on).
- Work hours: weekdays and from/to time; outside them, no alerts are shown, but events still appear in the menu with a note.
- Exclusion rules: field (title / location / notes) × comparison (contains / begins with / ends with / is / matches wildcard) × value, with a case-sensitive option. An event matching any rule gets no alert.
- Per-event: hide (no alert) or a custom alert time. Stored by event identifier, plus occurrence date for recurring events. A "Hidden events" list in Settings allows unhiding.

### General
- Start at login (SMAppService).
- Global hotkeys (user-configurable, unset by default): show menu, join current/next call, pause/resume alerts.
- Picks up calendar changes immediately (EKEventStoreChanged notification), plus a periodic refresh as a backstop.
- Permission onboarding: on first launch, request full Calendar access; if denied, a clear menu banner with "Open System Settings".

### Alert behavior details (Claude's calls, from builder review)
- **Data source:** Terry's work calendar is already visible in Calendar.app on the work laptop. EventKit is the only data source.
- **Pause and work hours drop alerts, they don't defer them.** An alert time that falls while alerts are paused, or outside work hours, is skipped. It doesn't show when the pause ends. Catching up after sleep/wake (see Anti-goals) applies only when nothing deliberately suppressed the alert.
- **Dismiss** ends alerts for that occurrence, including any later alert times.
- **Snooze** shows the alert again at the snooze time. Any alert times scheduled before that are skipped; ones after it still fire. "Until event start" snoozes to the start time.
- **Handled state is persisted:** dismissed and snoozed state is saved per occurrence (event ID + occurrence start) in Application Support. It's pruned once the event ends, so a relaunch or crash doesn't show alerts again for events already handled.
- **Focus:** the alert window activates and takes keyboard focus. The shortcut delay protects against stray keystrokes.
- **"Only accepted events"** counts events with no invitation, and events the user organized, as accepted. Only pending/tentative invitations are skipped.
- **Per-event customize** replaces the global alert times for that event. **Hide** and **Customize** both offer "this occurrence" or "all occurrences" for recurring events. "All occurrences" is keyed by the series' calendarItemIdentifier.

## Non-goals
- Reminders (Apple Reminders lists or in-app reminders).
- Themes or a theme editor (a single clean design that follows system light/dark).
- Widgets, iOS app, settings sync.
- Prompt "personalities", jokes, alarm clock animation, privacy mode, menu bar tint colours, custom sound import, rules for custom meeting-link services, running Shortcuts when joining.
- Any network calls: no Google/Microsoft sign-in, accounts, licensing, payments, analytics, crash reporting, update checks.
- Writing to the calendar in any way.

## Anti-goals (would be a failure even if it "works")
- A meeting alert that silently doesn't fire, e.g. because the app was asleep, a timer drifted, or the Mac woke from sleep past the alert time. Missed alerts that are still relevant (event not yet ended) must show on wake.
- Requiring Xcode, a paid account, or any sign-in just to build or run it.
- Anything that phones home.

## Constraints
- **Platform:** macOS 14 Sonoma or newer (Terry's personal Mac is on 26.4.1; work laptop version unknown, assumed ≥14). Universal binary (arm64 + x86_64).
- **Toolchain:** this Mac has only the Command Line Tools (Swift 6.3), not Xcode. The project must build with `swift build` (Swift Package Manager) plus a script that assembles the `.app` bundle (Info.plist, entitlements, icon) and signs it. No `.xcodeproj` required.
- **Dependencies:** none outside Apple frameworks (EventKit, SwiftUI, AppKit, Carbon for global hotkeys, ServiceManagement, AVFoundation/NSSound).
- **Permissions:** Info.plist carries `NSCalendarsFullAccessUsageDescription` (and the legacy `NSCalendarsUsageDescription`). App is `LSUIElement` (menu bar only, no Dock icon). Contacts access isn't needed; attendee names come from EventKit.
- **Distribution:** GitHub repo (Terry will create it). A GitHub Actions workflow on tag push builds the universal app, makes a DMG (`hdiutil`), and attaches it to a GitHub Release.
  - **Now:** ad-hoc signed (`codesign -s -`). Terry tests the install on a personal Mac and then on the work laptop (expect "Open Anyway" in Privacy & Security, if the company allows it).
  - **Later, optional:** Developer ID signing + notarization, enabled just by adding repo secrets (certificate, Apple ID/app-specific password or API key, team ID). The workflow must already contain these steps and skip them when the secrets are absent.
  - **Fallback:** a `scripts/install-from-source.sh` that builds and installs into `~/Applications` on any Mac with Command Line Tools. Locally built apps aren't quarantined, so Gatekeeper doesn't block them.
- **Settings storage:** UserDefaults, plus a JSON file in Application Support for per-event overrides and exclusion rules.

## Decided by Terry
- Read-only, local Apple Calendar data; no sign-ins.
- Feature scope as above; the "probably cut" list is cut.
- Distribute via GitHub as a DMG.
- Try ad-hoc signing first on personal devices; buy an Apple Developer account only if needed.

## Calls made by Claude (open to change)
- Name: **Showtime** (from the project folder name); bundle ID `com.terrythomas.showtime`.
- Swift + SwiftUI (`MenuBarExtra` for the menu, `Settings` scene), with AppKit `NSPanel` for the full-screen alert window, since SwiftUI windows can't reliably sit above full-screen spaces.
- macOS 14 minimum (needed for the EventKit full-access API and modern `MenuBarExtra`).
- Global hotkeys via Carbon `RegisterEventHotKey` instead of a third-party library.
- Alert scheduling: recompute the next alert from the event store on every change, wake, and minute tick, rather than queuing long-lived timers. This keeps it correct across sleep and clock changes.
- Same-time events grouped into one alert.
- MIT licence.

## Left to the builder
- Code structure, module boundaries, test approach (scheduling, filters, link detection and exclusion rules should be unit-testable without EventKit).
- Visual design of the alert and settings, within "clean, legible from across the room, follows light/dark".
- App icon.
- Exact wildcard syntax for exclusion rules (`*` and `?` recommended).

## Open questions
- **Travel time:** EventKit has no public travel-time property. The builder should check whether it's reachable (e.g. a private key on `EKEvent`); if not, drop the feature and say so.
- **Work laptop management:** if the company manages the laptop (MDM) and blocks either the Calendar permission or "Open Anyway", v1 needs Developer ID signing. The DMG test on the work laptop will show this.
- **Work laptop macOS version:** if it's older than 14, the minimum must drop and the full-access permission call needs a fallback.
