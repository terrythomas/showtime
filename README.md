# Showtime

A free macOS menu bar app that puts a full-screen alert in front of you before every meeting, with a one-click **Join** for the video call.

Showtime reads the calendars already in **Calendar.app** on your Mac. It has no sign-in, no account and no subscription, and it makes no network connections. That makes it suitable for a locked-down work laptop where you can't connect a third-party app to your work calendar.

## What it does

- **Full-screen alert** before each event. It shows the title, a live countdown, location, attendees and their responses, and notes, with buttons to **Join**, **Snooze** (two presets, custom, or until it starts), **Dismiss**, and **Show in Calendar**.
- **Join** finds the call link in the event: Zoom, Google Meet, Microsoft Teams (including Outlook "Safe Links"), Webex, GoToMeeting and about 15 more. Zoom and Teams open in their apps when installed.
- **Several alerts per event**, e.g. 10 minutes and 1 minute before. An event can have its own alert times, and you can hide single events or whole series.
- **Menu bar** shows the next meeting and a countdown, plus a list of ongoing and upcoming events.
- **Filters:**
  - pick which calendars count;
  - only accepted events;
  - only events with a video call;
  - all-day events on or off;
  - work hours;
  - exclusion rules (e.g. title contains "Lunch").
- **Pause alerts** for 15 min, 30 min, 1 hour, until the current event ends, the rest of today, or indefinitely.
- **Global keyboard shortcuts** to open the menu, join the current call, and pause or resume. The alert itself has keys too: Return joins, Esc dismisses, 1 or 2 snoozes, S snoozes until start, C opens Calendar.
- **System sound** when an alert appears, optionally repeating. Alerts can close automatically after a set time. Showtime can start at login.

## Install

### From a release (DMG)

1. Download `Showtime-x.y.z.dmg` from [Releases](../../releases), open it, and drag **Showtime** to **Applications**.
2. Open Showtime. If the release isn't notarized, macOS says *"Apple could not verify 'Showtime'…"*. In that case:
   - open **System Settings → Privacy & Security**;
   - scroll to the message about Showtime and click **Open Anyway**;
   - confirm.

   You only have to do this once. Some company-managed Macs hide this button. If yours does, use the next method or ask IT.
3. When asked, allow **full access to your calendars**.

### Build it on your Mac

You only need Apple's free Command Line Tools (`xcode-select --install`), not Xcode.

```bash
git clone <this repo> showtime && cd showtime
scripts/install-from-source.sh
```

This builds the app and installs it to `~/Applications/Showtime.app`. Apps built on your own Mac aren't blocked by Gatekeeper.

## Your work calendar

Showtime sees whatever Calendar.app sees. Add your work account under **System Settings → Internet Accounts** (Exchange, Google, iCloud…) or in **Calendar → Settings → Accounts**. Then choose which calendars Showtime uses under **Settings → Calendars**.

## Development

```bash
scripts/test.sh                       # unit tests (works with Command Line Tools only)
scripts/build-app.sh                  # build/Showtime.app, universal, ad-hoc signed
scripts/make-dmg.sh build/Showtime.app build/Showtime.dmg
```

`ShowtimeCore` (in `Sources/ShowtimeCore`) holds all the logic: scheduling, filters, link detection and settings. It's unit-tested. `Sources/Showtime` is the AppKit/SwiftUI app.

In debug builds, `SHOWTIME_DEBUG_EVENTS="Title@<unix time>[@<link>];…" .build/debug/Showtime` adds fake two-minute events, so you can try alerts without touching your calendar.

### Releases

Push a tag like `v0.1.0`. GitHub Actions tests, builds a universal app, makes a DMG and attaches it to a GitHub Release.

By default releases are ad-hoc signed and not notarized. To produce notarized releases, join the Apple Developer Program and add these repository secrets. No workflow changes are needed:

| Secret | Value |
|---|---|
| `MACOS_CERT_P12` | Your *Developer ID Application* certificate + key exported as .p12, base64-encoded (`base64 -i cert.p12 \| pbcopy`) |
| `MACOS_CERT_PASSWORD` | The .p12 export password |
| `APPLE_ID` | Your Apple ID email |
| `APPLE_APP_PASSWORD` | An app-specific password from appleid.apple.com |
| `APPLE_TEAM_ID` | Your 10-character team ID |

## Limitations

- **Travel time:** macOS doesn't officially give other apps Calendar's travel time. Showtime reads it through an unofficial route that works on macOS 26. If a future macOS removes it, "Include travel time" simply has no effect.
- Showtime only reads your calendars; it never changes them.
- Reminders aren't supported.

## Not affiliated

Showtime is an independent project. It was inspired by the idea of full-screen meeting alerts, but it isn't affiliated with, and shares no code or assets with, any other app.

## License

MIT
