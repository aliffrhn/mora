# Mora Gamification PRD

Status: Draft
Date: 2026-06-17
Owner: Product

## Summary

Mora should make daily focus feel tangible without turning a quiet menu bar timer into a noisy game. The gamification system should reward healthy Pomodoro completion: focus blocks are "circles", and a full set of four circles plus the long break earns one "mora".

The first version should clarify this loop, make progress more satisfying in the menu panel, and preserve Mora's minimalist character. The goal is motivation through completion, rhythm, and reflection, not pressure through social comparison or punitive streaks.

## Problem

The current menu shows today's circles, moras, and the hint "4 circles = 1 mora". This is compact, but it leaves several product questions unresolved:

- Users may not understand whether a mora is earned after four focus blocks, after starting a long break, or after completing the long break.
- The current progress display does not show partial progress toward the next mora.
- A count-only display can feel inert, especially at zero.
- Gamification can accidentally reward overwork if it only celebrates focus time and ignores breaks.
- Mora has no history view, so progress disappears at midnight without helping users understand their patterns.

## Goals

- Make the circle-to-mora loop immediately understandable.
- Reward completed focus cycles while also protecting rest.
- Make today's progress feel alive from the first completed circle.
- Keep the menu panel calm, fast to scan, and usable as the primary app surface.
- Store progress locally and avoid accounts, cloud sync, analytics, or social features.
- Create a foundation for later summaries, achievements, and preferences.

## Non-Goals

- No leaderboards, sharing feeds, competitive rankings, or social comparison.
- No punitive streak breaks, shame language, or productivity scoring.
- No currency economy, shop, unlock grind, or cosmetic marketplace.
- No account system or cloud sync.
- No complex quest system in the first release.

## Product Principles

1. Healthy completion beats raw output.
   Mora should reward a full rhythm: focus, breaks, and recovery.

2. The menu bar stays quiet.
   Progress should be visible when the user opens Mora, not constantly demanding attention.

3. Tiny wins should be legible.
   One completed circle should feel meaningful even before a mora is earned.

4. Progress should reset kindly.
   Daily reset is useful, but the product should not make yesterday feel like failure.

5. The metaphor should stay simple.
   "Circle" and "mora" are enough for MVP. Add more nouns only when they solve a real UX problem.

## Core Definitions

- Circle: one completed focus block.
- Cycle: four completed circles plus the associated long break.
- Mora: one banked healthy cycle.
- Banked mora: a mora that counts toward today's total after the long break is completed.
- In-progress mora: the current set of zero to four circles moving toward the next mora.

## Recommended Rule

Award one mora only after the long break completes following four focus circles.

This preserves the value of rest and matches the current implementation direction. To avoid confusion, the UI should not say only "4 circles = 1 mora". It should use clearer copy such as:

- "4 circles + long break = 1 mora"
- During long break: "Finish this break to bank 1 mora"
- After four circles before/during long break: "Mora ready after rest"

## Target Users

- Solo knowledge workers who want a lightweight focus rhythm.
- Students and makers who respond well to visible progress.
- Users who prefer a local, quiet utility over a productivity platform.
- People who want encouragement but are wary of streak anxiety.

## Primary User Stories

- As a user, I want to understand how moras are earned so progress feels fair.
- As a user, I want to see how close I am to the next mora so I feel momentum.
- As a user, I want breaks to feel like part of success, not interruption.
- As a user, I want today's effort to remain visible after each block.
- As a user, I want a simple history of recent days so progress does not vanish emotionally at midnight.

## MVP Scope

### 1. Clarified Progress Display

Update the menu progress section to show:

- Today's completed circles.
- Today's banked moras.
- A four-slot progress indicator for the current mora.
- Contextual helper text based on state.

Example states:

- 0 circles, 0 moras: "Complete 4 circles and the long break to earn a mora."
- 1 to 3 circles: "2 more circles until your long break."
- 4 circles, long break active: "Finish this break to bank 1 mora."
- Mora earned: "1 mora banked today."

### 2. Mora Progress Indicator

Represent the in-progress mora as four compact dots or rings:

- Empty slot: circle not completed.
- Filled slot: completed focus circle.
- Rest-ready state: all four slots filled with a subtle break/rest accent.
- Banked state: brief completion state after long break completion, then reset to empty for the next cycle.

This should remain readable in the existing menu panel width.

### 3. Completion Feedback

When a mora is earned:

- Play the existing cycle completion sound if sound is enabled.
- Show a calm inline confirmation in the menu panel, such as "Mora banked".
- Avoid persistent notifications in MVP unless the app already has an established notification pattern.

### 4. Daily Summary

Add a small summary row below today's progress:

- "Today: 6 circles, 1 mora"
- Optional secondary text: "Best rhythm: 2 moras" only after history exists.

For MVP, this can be limited to today. A full history view is a follow-up.

### 5. Local Persistence

Keep all gamification data in local persistence. Extend the current `DailyProgress` model only as needed.

Minimum data needed:

- Date.
- Completed circles.
- Banked moras.
- Current cycle count.
- Last mora earned timestamp, optional.

The existing `completedBlocks`, `morasEarned`, and `currentCycleCount` fields already cover the core MVP.

## Future Scope

### Recent History

Add a compact seven-day history in the menu panel or a future preferences/details window:

- One row of seven day markers.
- Each day shows moras earned.
- No broken-streak punishment.

### Gentle Goals

Allow users to set a daily intention:

- "Aim for 1 mora"
- "Aim for 2 moras"
- "No daily goal"

The default should be no explicit goal, or a lightweight suggested goal after the user has usage history.

### Rest Quality

Later, Mora can distinguish between:

- Earned mora: four circles plus completed long break.
- Focus-only cycle: four circles but skipped long break.

This can support reflective copy without punishment, such as "You focused hard. A full mora includes rest."

### Achievements

If added, achievements should be rare and behavior-shaping:

- First mora.
- First two-mora day.
- Five rest-complete moras.
- Three active days in a week.

Avoid achievements for excessive focus totals.

## Functional Requirements

### Progress Rules

- A focus block completion increments today's circle count.
- Completing a fourth focus block should move the current cycle into a rest-ready state.
- Completing the associated automatic long break should increment today's mora count by one.
- Skipping the long break should not bank a mora.
- Manual long breaks should not bank a mora unless they are explicitly tied to a completed four-circle cycle in a future design.
- Progress resets at local midnight.
- Persisted progress should normalize to the current local day on app launch.

### Menu UI

- The progress section must fit the existing menu panel width.
- Counts must remain visible at all times.
- The progress indicator must be legible at zero progress.
- Helper copy must change based on progress and timer phase.
- The section must not add modal steps or require setup.

### Accessibility

- Progress slots must have accessible labels, such as "2 of 4 circles complete".
- Color must not be the only way to distinguish states.
- Copy must be understandable without knowing Pomodoro terminology.
- VoiceOver should read today's circles and moras in a coherent order.

### Persistence

- Use local storage only.
- Existing users with saved `DailyProgress` should migrate without losing current counts.
- If new optional fields are added, decoding must provide defaults for older saved progress data.

## Edge Cases

- App is quit during a long break after four circles: Mora should bank only if the restored timer reaches long-break completion.
- App is asleep through long-break completion: Mora should bank once when the app refreshes after wake.
- User skips long break: Do not bank a mora.
- User starts a manual long break early: Do not bank a mora in MVP.
- User restarts focus block: Do not increment circles until a focus block completes.
- User crosses midnight mid-cycle: Current implementation resets daily progress when recording the next event. The PRD accepts this for MVP, but future design should decide whether an in-progress cycle belongs to start day or completion day.
- User completes more than four focus blocks through unusual state restoration: Do not award multiple moras from one long break.

## UX Copy

Use short, calm text:

- "Today's progress"
- "0 circles"
- "0 moras"
- "4 circles + long break = 1 mora"
- "2 more circles until long break"
- "Finish this break to bank 1 mora"
- "Mora banked"

Avoid:

- "Do not break your streak"
- "You failed"
- "Only X today"
- "Grind"
- "Rank"

## Success Metrics

Because Mora currently avoids analytics, these are product evaluation metrics rather than instrumented telemetry requirements:

- Users can explain how to earn a mora after seeing the menu once.
- Users report that breaks feel encouraged rather than optional.
- Users can tell how close they are to the next mora at a glance.
- The progress section remains readable at the current menu width.
- No increase in accidental break skipping due to reward timing.

If analytics are ever introduced, they should be opt-in and privacy-preserving.

## Acceptance Criteria

- The menu no longer relies on the ambiguous copy "4 circles = 1 mora".
- The menu shows current progress toward the next mora.
- A mora is awarded only once per eligible automatic four-circle cycle.
- Skipped long breaks do not award moras.
- Existing saved progress still decodes.
- Unit tests cover circle counting, mora banking, skipped long breaks, manual long breaks, and midnight reset behavior.
- The UI remains usable at the existing menu panel width.

## Open Questions

- Should a mora be awarded at long-break start instead of completion for users who feel four completed focus blocks should be enough?
- Should skipped long breaks produce a separate "focus cycle" stat, or remain invisible in MVP?
- Should the app eventually expose weekly history in the menu panel, or should history live in a separate details window?
- Should daily goals be user-set, suggested from history, or omitted entirely?
- Should circles count only completed 25-minute focus blocks, or should custom future focus durations still count equally?

## Implementation Notes

- `ProgressTracker` already owns daily progress and can remain the source of truth.
- `DailyProgress.completedBlocks` maps to today's circles.
- `DailyProgress.morasEarned` maps to banked moras.
- `DailyProgress.currentCycleCount` maps to in-progress mora slots.
- `CycleStateMachine.onFocusBlockComplete` already reports completed block index.
- `CycleStateMachine.onBreakComplete` already identifies long breaks and manual breaks.
- `StatusMenuContent.progressSection` is the main MVP UI surface.
- `AppModel` likely needs a published value for current cycle progress and possibly helper copy.
- Tests should remain centered on `ProgressTracker` and `CycleStateMachine` integration behavior.

## Proposed Milestones

### Milestone 1: Make the loop clear

- Update progress copy.
- Show four-slot current mora progress.
- Add helper text based on current phase and cycle count.
- Add unit tests for visible progress state.

### Milestone 2: Make mora earning satisfying

- Add "Mora banked" transient menu state.
- Confirm sound timing.
- Add tests for skipped and completed long breaks.

### Milestone 3: Add reflection

- Add seven-day local history.
- Add optional daily intention.
- Add a compact summary without streak punishment.
