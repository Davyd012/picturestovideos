# Editor clip workflow improvement plan

## Implementation status (2026-10-31)

This plan is **not complete**. The following first slice is present in the working tree:

- `MoveTimelineClipUseCase` moves a committed occurrence by `clipId` to a validated 1-based position. It assigns clip content and identity to the existing time slots, retaining each slot's boundaries and setting `hasManualEdits`. The timeline ViewModel exposes `clipMoved` and updates serialized project state.
- The clip list has a validated position-move dialog in timeline sort order. Row selection seeks without opening the editor; editing has a separate action. Selection remains local to the list.
- The selected row uses a surface role and a check icon with selected semantics. Empty queues no longer show sample clips, and the fabricated queue timestamps were removed. The queue count is localized in English, Norwegian, and Russian.
- A 56-clip use-case test covers moves involving the final positions, duplicate source media, preserved gaps and boundaries, invalid input, and serializer round-trip. Existing editor tests were adjusted for the separate edit action.

Verification so far: the new use-case tests and affected clip-list/editor tests passed. A full `flutter test` run was stopped after reporting at least one failure; its details were truncated and the failure is not yet diagnosed. `flutter analyze` was stopped before completion. No Android device was connected, so the reported drag failure was not reproduced on the specified device. Available emulator definitions were listed, but none was running. Do not treat the implementation or acceptance criteria as verified.

### Remaining work

Complete every unchecked requirement in sections 1–6 below. In particular:

- Reproduce the reported last-two drag issue with a representative 56-clip sequence; identify the affected list, scroll bounds, callback indices, and sync behavior. Record device and configuration.
- Audit the new move operation against legacy payloads, transition rules, persistence/reopen, preview and export, queue operations, and all timing invariants. Add the missing ViewModel and project-shaped regression tests. Confirm and surface successful moves and handle stale IDs without misleading feedback.
- Replace the competing lists with the planned bounded, lazy timeline workspace, accessible reorder mode and actual drag auto-scroll. Keep queue and bulk tools clearly scoped and collapsible. Explain view-only sorts and restore timeline order directly.
- Move selection into feature-scoped Riverpod state. Implement persistent responsive preview, selected/playing clip reveal actions, direct draft framing with apply/cancel/reset, playback and stale-preview handling, and previous/next editing with an unsaved-change decision.
- Complete localization, focus and semantics, large-text and light/dark contrast checks. Verify state survives tab changes and protect existing edits across every queue and restore entry point.
- Run and diagnose `flutter analyze`, targeted tests, and the complete test suite. Add real drag, scrolling, playback, and preview tests. Run the Android integration flow and profile/manual checks described below, recording unavailable checks and their reasons.

Preserve all unrelated pre-existing working-tree changes. The plan file and several editor, localization, and test files were already modified or untracked before this slice; inspect the current tree before editing.

## Goal and acceptance

Make every timeline clip, including the final two, easy to find, preview, edit, and move without losing context. Provide one clear clip workspace, with optional controls that can be hidden. Preserve existing projects and edits. This is a plan only; implementation and device validation remain outstanding.

## Current evidence and investigation

- `audio_editor_screen.dart` places the preview, playback controls, and tab content in one vertical `ListView`. A long clip list moves the preview offscreen.
- `clips_tab_view.dart` renders `ClipCaptionsEditor` followed by a separate queued-media list. Reorder and numbered moves are available only in the latter. The first list represents timeline occurrences; the second represents unique selected media. They are not interchangeable.
- `ClipCaptionList` stores selection locally, and a row tap both seeks and opens the editor. The selected row sets both the card and `ListTile` background, while `ListTile.selected` can also change content colors. This is a plausible cause of the bright rectangle and poor contrast in the screenshot; verify against the active theme before fixing.
- Queue moves in `editor_media_selection_view_model.dart` call `syncSelectedMediaToMarkers`; restoring the queue deduplicates by media ID. Repeated timeline occurrences therefore need clip-ID-based operations. A queue reorder cannot be assumed to reorder each occurrence independently or preserve all timing and edits.
- The queued list is nested, shrink-wrapped, and non-scrollable. Its displayed times are `index * 3 seconds`, not actual timeline timing. Existing reorder widget test invokes a callback directly and does not test dragging or the last rows.
- `onSelectTimelineClip` seeks to the clip start; the edit dialog contains framing, timing, caption, motion, and transition controls. The editing preview and separately rendered preview have different freshness semantics.

First reproduce the reported last-two failure on a device with the same long sequence. Record whether it occurs in the committed timeline list, the queued list, or both; inspect scroll bounds, drag auto-scroll, callback indices, and state after sync. Do not assume an index arithmetic defect until reproduced. Preserve unrelated in-progress changes in the working tree when implementing this plan.

## 1. Define clip ordering and safe mutations

1. Make the committed timeline the source of truth for the editor clip list. Identify every occurrence by `clipId`, never filename, row index, or `mediaId`. Distinguish queued-but-not-placed media from committed clips in a separately labeled, collapsible section if both must remain available. Do not show sample clips as real content when empty.
2. Add a timeline ViewModel intent and a testable domain/use-case operation to move one occurrence to a validated, 1-based destination. Use one internal index convention and explicitly adapt Flutter's actual reorder callback semantics once; test both directions, adjacency, first and last positions, no-op, and invalid or stale IDs. A successful operation is atomic and persists through the existing project-save path.
3. Before implementing, trace `syncSelectedMediaToMarkers`, track/event serialization, boundary editing, marker snapping, transitions, preview resolution, and export. Document current invariants and select an explicit timing policy: preserve timeline slots and their boundaries while moving whole clip content/identity and clip-specific edits into the chosen slot. Preserve project duration, markers, audio, and gaps; re-evaluate transition validity with new neighbors. If existing timeline constraints make this policy impossible, specify and test an equivalent non-destructive policy before implementation; never silently rebuild or discard customized timing.
4. Preserve per-occurrence caption, caption style, framing, motion, and transition data. Keep clip IDs stable; repeated media must remain independently editable. Define what happens when a transition moves to or from the last position: retain its stored setting, apply only when a next clip exists, and enforce existing duration/capability rules. Do not overwrite the queue or other occurrences during a clip move.
5. Ensure queue operations remain clearly scoped to queue ordering and do not implicitly replace a manually edited timeline. Audit all entry points, including staged library ordering and project restore, for unintended timeline rebuilds. If a queue resync necessarily changes a customized timeline, present its existing explicit review/confirmation flow and describe the effect; no silent data loss.

## 2. One usable clip workspace

1. Replace the two competing full lists with a single compact, lazily built timeline list. Show thumbnail, actual timeline number and start/end, concise caption status, and a clear selected indicator. Keep sort as a view-only option; expose reordering only in timeline order, with a localized explanation and a direct way back to timeline order when another sort is active. Reordering must not mutate sort or change displayed numbers ambiguously.
2. Use a bounded primary scrolling region with drag handles and edge auto-scroll; do not nest a shrink-wrapped reorder list in the page scroll. Provide an accessible **Move to position** action for long moves and for screen-reader/keyboard users. Validate empty, nonnumeric, zero, and out-of-range input with visible localized feedback; allow positions 1 through clip count, including the last two. Confirm the destination after moving and retain selection and focus by clip ID.
3. Offer a clear **Reorder** mode: show drag handles and move actions only when enabled; keep edit/delete in a compact overflow menu or selected-clip controls. Exit the mode without changing data. Put bulk crop/fit actions in a labeled expandable tools section. Ensure modes and sections have accessible labels, state, and adequate touch targets; retain their state while switching tabs during the editor session.
4. Keep queued media accessible for images not yet on the timeline, but label its purpose and effects. Use real project timings for committed clips; do not fabricate timestamps. Avoid disrupting the existing add, remove, bulk fit, and recovery flows.

## 3. Preview and edit without losing the clip

1. Restructure the mobile Clips view around a compact, persistent editing preview and playback controls above a separately scrolling list; adapt height for landscape, small screens, large text, keyboard, and safe areas. If space is insufficient, offer an explicit preview expand/collapse control and an accessible way to return to the selected clip. Keep other tabs usable and avoid multiple competing vertical scroll gestures.
2. Row tap selects the clip and seeks to a deterministic point inside its actual interval, without opening edit. Provide a separate, labeled Edit action. Make selection a single feature-scoped Riverpod state keyed by `clipId`; selection, list, player, and editor read the same state. Playback can advance independently: indicate the playing clip separately and do not unexpectedly replace the user's editing selection. Provide a direct **Show playing clip** / **Show selected clip** action, scrolling the lazy list to that ID without losing the current sort or focus.
3. Allow editing framing directly against the selected image in the visible preview, using the project's output aspect ratio and the existing crop transform and renderer rules. Provide explicit enter, apply, cancel, and reset controls; preserve a draft until apply, restore it on cancel, and prevent playback gestures from accidentally changing the crop. Keep an accessible non-gesture adjustment path. Reuse existing framing logic rather than maintaining a second divergent transform implementation.
4. Organize existing edit controls into understandable sections for framing, timing, captions, motion, and transitions; keep the selected image visible where space permits. Preserve capability notices, timing validation, snap rules, apply-to-all confirmation, and save/cancel behavior. Provide previous/next clip navigation with a clear unsaved-change decision; the final clip must not expose an invalid next transition.
5. Keep the live editing preview synchronized with selection, seek, and applied edits. Clearly distinguish it from the rendered/export preview and mark the latter stale after relevant changes. Handle playback loading, seek failures, unavailable media, rapid selection, edits while playing, and navigation/disposal without showing an old frame as current. Preserve or explicitly pause playback while editing; test the chosen behavior.

## 4. Correct selected-row appearance

Use one Material 3 selected treatment with an appropriate surface or primary-container role and matching on-container foreground. Keep card shape and clipping consistent; remove overlapping card/tile fills and framework-selected foreground conflicts. Avoid primary borders and saturated full-row highlights; use a non-color selected cue and semantic selected state. Verify text, subtitle, icons, focus, pressed, and disabled contrast in the actual light and dark themes, including the screenshot's theme. No hardcoded colors, text styles, radii, or spacing; use existing theme and design tokens.

## 5. Architecture, accessibility, and localization

- Keep project mutations and selection intents in Riverpod ViewModels; immutable state, clip-ID commands, and repository-backed persistence. Widgets own only ephemeral gesture/scroll mechanics; avoid `BuildContext` in ViewModels. Separate small feature widgets and use typed navigation where needed.
- Add all visible labels, errors, tooltips, and semantic announcements through `context.l10n`, `AppLocalizations`, and English, Norwegian, and Russian language files. Localize position ranges and counts; check long translations, RTL readiness, text scaling, keyboard focus, TalkBack/VoiceOver, and non-color selection cues.
- Use Material 3 defaults and existing context theme extensions. Use restrained implicit animation only where useful, respect reduced-motion settings, and avoid expensive work during build or each playback tick. Load only visible thumbnails; avoid repeated full-list file-stat work and quadratic repeated-occurrence scans for long projects.

## 6. Verification and rollout

1. Add ViewModel/use-case tests with real project-shaped fixtures: first/last two moves in both directions, long-distance and no-op moves, duplicate media occurrences, empty/single clip, missing IDs, invalid positions, customized boundaries/gaps, transitions, markers, and persistence/reopen. Verify all clip properties, project duration, queue behavior, preview order, and export input remain correct.
2. Add widget tests using actual drag gestures and scrolling, not direct callback invocation: drag near list edges and move clips 55/56 in a 56-clip sequence; numbered moves to/from 1 and 56; invalid input; mode toggles; view-only sort; selection and edit actions; selected-row semantics and contrasting theme roles; focus after reorder; large text and constrained viewport. Override providers and mock plugin dependencies.
3. Add playback/preview tests for select-to-seek, playing versus selected identity, reveal selected/playing item, rapid seeks, stale rendered preview, framing apply/cancel, and missing media. Add a targeted integration flow on Android with 56 clips: select a final clip, preview, crop, reorder, save, reopen, and verify playback/export ordering and preserved edits. Exercise the same critical flow with repeated source media.
4. Run `flutter analyze`, targeted `flutter test` files, then `flutter test`; run the relevant integration test on an available device. Profile scrolling and drag auto-scroll on a representative low-end device in profile mode. Record device, screen size, theme, locale, results, and any unavailable checks. Manually verify portrait/landscape, dark/light, accessibility, and the two reported screenshots' scenarios.
5. Deliver in reviewable slices: reproduce and lock invariants; implement safe timeline mutation; build unified list and reorder controls; integrate selection/preview/framing; refine selected styling and localization; run full regression and device checks. Acceptance requires all clips reachable and movable, no unexpected loss of edits or timing, a visible path between clip and preview, and a readable selected state.
