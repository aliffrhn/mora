# Mora

Minimalist macOS menu bar focus timer (25/5/15) with full-screen break overlays and daily progress tracking. Currently **WIP/pre-release**—expect rough edges while core flows and idle handling are still being shaped.

## Status
- Work in progress; not production-ready. Behavior and UI may change.
- Idle auto-pause is planned but not implemented; expect missing polish and potential bugs.
- Not ready for general use; expect breakage and UI/shortcut changes.

## End Goal
- Minimal, reliable macOS menu bar Pomodoro timer (25/5/15) that stays out of the way, enforces breaks, and keeps focus time honest.

## Project Goals
- Menu bar first: start/pause/resume without window juggling; global shortcuts for every command.
- Accurate timing: auto-transitions, persistence, and upcoming idle auto-pause keep focus tracking aligned with reality.
- Respectful breaks: full-screen overlays on all displays with gentle countdowns and sounds you can mute.
- Lightweight state: simple persistence for cycles/today’s blocks so relaunching is predictable.

## Current Capabilities
- 25/5/15 Pomodoro-style cadence with automatic phase transitions and chimes (distinct for focus, break, cycle complete).
- Menu bar UI showing live countdown, phase, and controls (start, pause, resume, restart, skip break, quit).
- Full-screen break overlay per display with circular countdown and skip/dismiss controls.
- Progress tracking for “Today’s blocks” and “Moras earned” plus basic sound preference persistence.
- Global hotkey support via `HotKey` and Combine-driven state propagation.

## Known Gaps (current WIP)
- Idle auto-pause not implemented; no idle threshold controls yet.
- Preferences are minimal (sound toggle only); no autostart or customization for durations.
- Limited error handling and edge-case coverage; expect occasional UI roughness.

## Roadmap (high-level)
1) **001-mora-menu-bar-timer** — baseline menu bar timer, overlays, sounds, and cycle tracking (initial implementation present, polish ongoing).
2) **001-idle-autopause** — detect keyboard/mouse inactivity, auto-pause focus blocks, and prompt on return (design/spec drafted; implementation pending).
3) **Next candidates** — richer preferences (thresholds, autostart), progress summaries, and UX polish from usability feedback.

## Commands / Shortcuts (intended)
- Start focus
- Pause / Resume
- Restart phase
- Skip break
- Quit

## Getting Started
**Requirements:** macOS 13+, Xcode 15+/Swift 5.10+, SwiftPM dependencies (`HotKey`, `combine-schedulers`).

Build/Run (recommended):
1. `swift package resolve`
2. `open Mora.xcodeproj` and run the `Mora` scheme (menu bar app).

CLI alternative (for quick smoke): `swift run Mora`

Tests: `swift test`

## Tech Stack
- Swift 5.10, AppKit + SwiftUI menu bar app, Combine for state propagation, HotKey for global shortcuts.

## Screenshots
- Current menu bar panel (WIP): shows today's circles/moras, live countdown, Pause/Restart work session, Start short/long break, and Quit.
