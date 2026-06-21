# Configurable Timer Durations PRD

Status: Draft
Date: 2026-06-21
Owner: Product

## Summary

Mora should let users configure all three timer durations while preserving familiar Pomodoro defaults and the existing four-circle mora loop.

The Settings window will expose:

- Focus duration, default 25 minutes.
- Short-break duration, default 5 minutes.
- Long-break duration, default 15 minutes.

Each value persists locally and applies the next time that phase begins. Changing a preference must not silently add or remove time from an active, paused, or restored phase. Explicitly restarting a phase uses the latest saved duration.

This feature gives users meaningful control over their work and recovery rhythm without introducing schedules, presets, accounts, or a complex timer builder.

## Problem

Mora currently uses a fixed 25/5/15 cycle:

- 25 minutes of focus.
- 5 minutes for each short break.
- 15 minutes for the long break after four focus blocks.

These defaults are familiar, but one rhythm does not fit every user or task:

- Deep-work sessions may need longer focus blocks.
- New users may benefit from shorter focus blocks while building a routine.
- Some users need brief short breaks; others need enough time to move or reset.
- A fixed long break may be too short for lunch or too long for a constrained schedule.
- A mismatched break duration can encourage users to skip rest, which conflicts with Mora's rest-centered mora reward.
- Users cannot currently see or change the durations Mora will use for upcoming phases.

The domain already models all three durations in `CycleStateMachine.Configuration`, but the values are immutable after initialization and fixed to 25/5/15.

## Goals

- Let users configure focus, short-break, and long-break durations independently.
- Preserve 25/5/15 as the default for existing and new users.
- Persist duration preferences across app launches.
- Apply changes consistently to automatic and manually started phases.
- Keep active and restored timers stable when settings change.
- Make an explicit Restart action adopt the latest saved duration.
- Keep circle and mora rules understandable at every supported duration.
- Fit all controls naturally into Mora's existing macOS Settings window.

## Non-Goals

- No per-day or per-cycle schedules.
- No automatic recommendations based on usage.
- No named presets such as Classic or Deep Work in the first release.
- No separate duration for each focus block in a four-block cycle.
- No separate manual-break and automatic-break durations.
- No arbitrary seconds or fractional-minute input.
- No configurable number of circles per mora.
- No cloud sync or account-based preference storage.
- No analytics or productivity scoring.

## Product Principles

1. Defaults should work immediately.
   Users who never open Settings continue to receive the familiar 25/5/15 rhythm.

2. Configuration should remain small and legible.
   Three duration controls are enough. Mora should not become a scheduling system.

3. Timer changes should never surprise the user.
   Editing a preference must not mutate a countdown already in progress.

4. Explicit actions can apply new intent.
   Restarting a phase uses the latest setting because the user deliberately begins that phase again.

5. Rest remains part of success.
   Custom durations do not remove the requirement to complete an eligible automatic long break before banking a mora.

## Target Users

- Users who prefer focus sessions longer or shorter than 25 minutes.
- Users whose work requires a different recovery rhythm.
- Users who skip breaks because the fixed duration does not fit their routine.
- Students or new focus-timer users who want shorter starting sessions.
- Existing Mora users who want control without complex configuration.

## User Stories

- As a user, I want to choose a focus duration that fits my task.
- As a user, I want short and long breaks to fit my recovery needs.
- As a user, I want Mora to remember all three durations after relaunching.
- As a user, I want automatic and manual breaks to use the same saved preferences.
- As a user, I want changing a setting to affect future phases without altering my current countdown.
- As a user, I want Restart to begin the current phase again using my latest setting.
- As a user, I want custom focus blocks and long breaks to participate in the existing circle and mora rules.

## Recommended Experience

### Settings Layout

Add a `Timer` section above the existing sound preference:

```text
Timer
Focus                       25 min  [-] [+]
Short break                  5 min  [-] [+]
Long break                  15 min  [-] [+]

Restore Defaults

Sound
Play sounds                              On
```

Use native macOS `Stepper` controls with visible values. Avoid free-form text fields so unsupported values cannot be entered.

### Default Values And Ranges

| Setting | Default | Minimum | Maximum | Increment |
| --- | ---: | ---: | ---: | ---: |
| Focus | 25 min | 10 min | 120 min | 5 min |
| Short break | 5 min | 1 min | 10 min | 1 min |
| Long break | 15 min | 10 min | 60 min | 5 min |

Rationale:

- A 25-minute focus default preserves Mora's existing Pomodoro behavior.
- A 10-minute focus minimum keeps a completed circle meaningful while supporting shorter sessions.
- A 120-minute focus maximum supports deep work without creating an effectively unbounded timer.
- A 1-to-10-minute short-break range supports quick recovery between circles.
- A 10-to-60-minute long-break range distinguishes substantial recovery while supporting meals and longer resets.
- A 15-minute long-break default preserves Mora's existing behavior.

The ranges are independent. Mora should not silently alter one setting when another changes.

### Display Copy

- `Focus`
- `Short break`
- `Long break`
- `25 min`, `5 min`, and `15 min`
- `Restore Defaults`
- Settings section: `Timer`

Accessibility values should use full units, such as `25 minutes`.

Avoid instructional paragraphs inside Settings. The labels, values, and native controls should be self-explanatory.

### Restore Defaults

`Restore Defaults` sets the saved values to 25/5/15.

- It does not alter an active, paused, or restored countdown.
- It updates the idle focus preview immediately when Mora is idle.
- It affects each phase the next time that phase begins.
- If the user explicitly restarts the active phase, the restored default for that phase is used.
- No confirmation dialog is required because the action is reversible through the steppers.

## When Changes Apply

### General Rule

A saved duration applies the next time its corresponding phase begins. The current timer remains unchanged unless the user selects Restart.

| Current state | Focus setting change | Short-break setting change | Long-break setting change |
| --- | --- | --- | --- |
| Idle | Update the idle focus preview immediately. | Save for next short break. | Save for next long break. |
| Focus | Keep current focus unchanged; use next focus. | Save for next short break. | Save for next long break. |
| Short break | Save for next focus. | Keep current break unchanged; use next short break. | Save for next long break. |
| Long break | Save for next focus. | Save for next short break. | Keep current break unchanged; use next long break. |
| Any paused phase | Keep remaining time unchanged. | Keep remaining time unchanged. | Keep remaining time unchanged. |
| Any restored phase | Honor persisted timing. | Honor persisted timing. | Honor persisted timing. |

### Restart Behavior

Restarting uses the latest saved duration for the active underlying phase.

Example:

1. A 25-minute focus session begins.
2. The user changes Focus to 45 minutes.
3. The active countdown remains unchanged.
4. The user selects Restart.
5. Focus restarts at 45:00.

The same rule applies to active or paused short and long breaks.

### Idle Behavior

When Mora is idle, changing Focus updates the visible idle countdown immediately because no timer is active. Changing either break duration has no additional idle-menu effect.

## Core Timer Rules

### Focus

- Starting focus from idle uses the latest focus duration.
- Each automatic focus block uses the latest focus duration when it begins.
- Restarting focus uses the latest focus duration.
- Completing a focus block increments today's circle count once, regardless of duration.
- Pausing, resuming, sleeping, or restoring must not recalculate the active focus duration.

### Short Break

- Automatic short breaks use the latest short-break duration when they begin.
- `Start short break` uses the same latest duration.
- Restarting a short break uses the latest short-break duration.
- Completing or skipping a short break follows the existing cycle transition behavior.
- Short-break duration does not directly affect mora banking.

### Long Break

- The automatic long break after the fourth circle uses the latest long-break duration when it begins.
- `Start long break` uses the same latest duration.
- Restarting a long break uses the latest long-break duration.
- Completing an eligible automatic long break banks one mora.
- Skipping the eligible automatic long break banks no mora.
- Completing a manually started long break banks no mora under the existing gamification rules.

## Interaction With Gamification

The mora rule remains:

```text
4 completed circles + completed automatic long break = 1 mora
```

Duration changes do not change the reward amount:

- A completed 10-minute focus block counts as one circle.
- A completed 120-minute focus block also counts as one circle.
- Four completed focus blocks are still required for an eligible long break.
- An eligible 10-minute long break banks one mora when completed.
- An eligible 60-minute long break also banks one mora when completed.
- Skipping the eligible long break banks zero moras.
- Manual long breaks bank zero moras.

Mora is a self-directed local tool, so custom duration is not weighted or scored. The product should not imply that a longer focus block earns more value than a shorter completed block.

## Functional Requirements

### Preference Model

Add three published integer preferences to `PreferenceStore`:

- `focusDurationMinutes`
- `shortBreakDurationMinutes`
- `longBreakDurationMinutes`

Requirements:

- Persist each value under a Mora-specific `UserDefaults` key.
- Register 25/5/15 as defaults.
- Sanitize values loaded from storage before use.
- Existing users without these keys receive 25/5/15 automatically.
- Expose a `restoreTimerDurationDefaults()` action.
- Convert minutes to seconds only at the state-machine boundary.

### Value Validation

- Clamp each value to its own supported range.
- Normalize unsupported values to the nearest valid increment.
- Missing, zero, unreadable, or non-finite values fall back to that setting's default.
- Persist normalized values so invalid storage does not recur.
- Resolve equal-distance rounding toward the larger supported value.

Examples:

- Focus 43 normalizes to 45.
- Focus 3 normalizes to 10.
- Short break 14 normalizes to 10.
- Long break 17 normalizes to 15.
- Long break 58 normalizes to 60.

### State-Machine Integration

- `CycleStateMachine` must accept duration updates after initialization.
- Updating configuration must not restart or mutate an active phase.
- Each phase transition reads the latest corresponding duration.
- Automatic and manual entry points use the same duration source.
- `restartPhase` reads the latest saved duration for the underlying phase.
- Updating Focus while idle refreshes the idle `TimerState.remaining` value.
- Pause and resume continue using captured remaining time.
- Sleep and wake recovery continue using the active target date.

### Settings UI

- Add a `Timer` section to `SettingsView`.
- Show three labeled steppers with visible minute values.
- Keep each control inside stable layout dimensions so values do not shift the form.
- Add a `Restore Defaults` command below the duration controls.
- Keep the sound toggle in a separate `Sound` section.
- Support keyboard navigation and VoiceOver.
- Prevent each stepper from exceeding its range.

### App Model

- The idle countdown should reflect `focusDurationMinutes` instead of a hard-coded `25:00`.
- Active countdown formatting remains based on `TimerState.remaining`.
- No additional duration text is required in the menu progress section.

### Persistence And Restoration

- Duration preferences remain independent from active timer-state persistence.
- `TimerState` continues storing phase, remaining time, target date, and start date.
- No timer-state migration is required.
- A restored active or paused phase honors persisted timing even if preferences changed while Mora was closed.
- The next phase transition uses the latest saved duration.
- Explicitly restarting a restored phase uses the latest saved duration.

## Edge Cases

- Focus changes one second before the current focus completes: current focus completes normally; the next focus uses the new value.
- Short break changes one second before focus completion: the upcoming short break uses the new value.
- Long break changes one second before the fourth focus completes: the upcoming long break uses the new value.
- A setting changes after its phase starts: active remaining time and target date remain unchanged.
- A setting changes while its phase is paused: paused remaining time remains unchanged.
- The user restarts after changing a setting: restart uses the new value.
- Restore Defaults is selected during a phase: current countdown remains unchanged.
- Mora quits during a custom phase: relaunch honors the persisted target date or paused remaining time.
- The Mac sleeps through completion: wake handling completes the active phase once.
- A custom automatic long break completes: bank one mora exactly once.
- A custom automatic long break is skipped: bank no mora.
- A custom manual long break completes: bank no mora.
- A stored value is outside its range: normalize it before constructing timer configuration.
- Multiple Settings windows edit the same preference: all views reflect the published value.
- Local midnight occurs during a cycle: existing daily-progress behavior remains unchanged.
- Focus is changed while idle: idle countdown updates without starting the timer.

## Accessibility

- VoiceOver announces each label, value, and control role.
- Example: `Focus, 25 minutes, stepper`.
- Example: `Short break, 5 minutes, stepper`.
- Example: `Long break, 15 minutes, stepper`.
- Increment and decrement actions use the setting's documented step.
- The controls work with keyboard navigation.
- Values include the minute unit rather than a bare number.
- Text remains readable at larger accessibility sizes without clipping.
- Restore Defaults has a clear accessibility label and command role.

## Privacy

- Store all preferences locally in `UserDefaults`.
- Do not add analytics, accounts, or cloud synchronization.
- Do not infer health, productivity, or schedule information from selected durations.

## Success Measures

Mora currently avoids analytics, so these are product evaluation criteria:

- Users can find and change all three durations without instructions.
- Users understand that changes affect upcoming phases, not active countdowns.
- Existing users retain 25/5/15 without setup.
- Users can restore the standard values easily.
- No reports of countdowns unexpectedly changing after preference edits.
- Circle and mora behavior remains consistent across all supported durations.
- Settings remains calm and understandable despite adding three controls.

## Acceptance Criteria

- Settings exposes Focus, Short break, and Long break duration controls.
- Defaults are 25, 5, and 15 minutes respectively.
- Focus supports 10 to 120 minutes in 5-minute increments.
- Short break supports 1 to 10 minutes in 1-minute increments.
- Long break supports 10 to 60 minutes in 5-minute increments.
- All values persist across app relaunches.
- Existing installations without saved duration keys use 25/5/15.
- Invalid stored values normalize safely.
- Each newly started phase uses its latest corresponding preference.
- Manual breaks use the same values as automatic breaks.
- Changing settings does not alter active, paused, or restored timing.
- Restart uses the latest duration for the active underlying phase.
- Focus changes update the idle countdown immediately.
- Restore Defaults saves 25/5/15 without mutating an active timer.
- Every completed custom focus block counts as one circle.
- Completing an eligible custom automatic long break banks exactly one mora.
- Skipping it or completing a manual long break banks no mora.
- VoiceOver and keyboard users can operate every duration control.

## Test Plan

### PreferenceStore Tests

- Defaults to 25/5/15.
- Saves and reloads each supported value.
- Clamps each setting to its own range.
- Rounds each setting to its documented increment.
- Falls back correctly for missing, zero, or invalid values.
- Restore Defaults writes 25/5/15.

### CycleStateMachine Tests

- Focus starts with the configured focus duration.
- Automatic and manual short breaks use the configured short-break duration.
- Automatic and manual long breaks use the configured long-break duration.
- Updating a future phase duration affects its next transition.
- Updating the active phase duration does not change remaining time or target date.
- Updating a paused phase duration does not change paused remaining time.
- Restarting focus uses the latest focus duration.
- Restarting short break uses the latest short-break duration.
- Restarting long break uses the latest long-break duration.
- Restored phases honor persisted timing.
- The phase after restoration uses the latest preference.
- Idle focus preview updates when Focus changes.

### Gamification Regression Tests

- Every supported focus duration awards one circle on completion.
- Focus restart does not award a circle before completion.
- Four custom focus blocks lead to the automatic long break.
- Completing an eligible custom long break awards one mora.
- Skipping it awards none.
- A manual custom long break awards none.
- Duration length never changes the mora amount.

### UI Tests

- All three steppers render their default and saved values.
- Each stepper stays within its own bounds.
- Restore Defaults updates all three controls.
- VoiceOver values contain the minute unit.
- Keyboard increment and decrement use the correct step.
- Settings remains usable at supported text sizes.

## Implementation Notes

- `CycleStateMachine.Configuration` already contains all three durations but is currently immutable.
- Introduce a small `TimerDurationSettings` value type or equivalent to group minute preferences and validation rules.
- `PreferenceStore` should remain the persisted source of truth.
- `MenuBarController` should subscribe to all three published preferences and update future state-machine configuration.
- `CycleStateMachine` should update its configuration without mutating `timerState` during an active phase.
- `CycleStateMachine.restartPhase` should read the latest configured duration.
- Idle configuration updates need a narrow state-machine method so the idle focus preview remains correct.
- `TimerState` already preserves active and restored timing.
- `SettingsView` currently exposes only sound and is the intended surface for the duration controls.
- The break overlay derives progress from the active timer state's timing and should continue to work with custom break lengths.
- Existing `ProgressTracker` rules can remain duration-independent.

## Proposed Milestones

### Milestone 1: Preference Model

- Add the three duration preferences and validation rules.
- Add restore-default behavior.
- Add focused preference tests.

### Milestone 2: Timer Integration

- Make state-machine duration configuration updateable.
- Preserve active, paused, restored, sleep, and wake behavior.
- Update idle focus preview behavior.
- Add state-machine and gamification regression tests.

### Milestone 3: Settings UI

- Add the Timer settings section and three steppers.
- Add Restore Defaults.
- Add accessibility labels and keyboard behavior.
- Verify layout at supported text sizes.

## Future Scope

- Named presets such as Classic, Deep Work, and Gentle.
- Configurable number of focus blocks before a long break.
- Optional per-day schedules.
- Different durations for individual blocks in a cycle.
- Showing upcoming phase durations in the menu panel.
- Exporting and importing timer profiles.

## Open Questions

- Should short break allow values above 10 minutes? Recommendation: keep the first release compact at 1 to 10.
- Should focus allow values below 10 minutes? Recommendation: keep 10 as the minimum so a circle remains meaningful.
- Should a 10-minute short break and 10-minute long break be allowed simultaneously? Recommendation: yes; avoid silently coupling independent controls.
- Should longer focus blocks award more circles? Recommendation: no; one completed focus phase remains one circle.
- Should Settings eventually offer presets? Recommendation: evaluate after observing how users configure the three values.
