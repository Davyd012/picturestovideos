# Caption editor design and implementation guide

## Goal

Make clip titles and supporting lines easy to place, read, and style. The user should see the result on the actual clip while editing. The finished video should match the editing preview.

This document is a proposal, not an implementation. Follow `AGENTS.md` and `docs/ai/` for architecture, Material 3, theming, localization, animation, and testing. App UI colors and typography must come from the existing theme; caption colors and fonts are video content settings, not app UI theme overrides.

## Current behavior

- Each clip has a title and optional supporting line. The existing editor also exposes placement, entrance, and timing.
- Placement is top, center, or bottom. Caption sizing and line wrapping are computed by `CaptionLayout` and shared with export.
- Export currently draws each line group separately in white with a dark box. The preview and export must be reviewed together when changing the layout.
- Long text can be shortened and there are existing overflow and reading-time warnings. Rendering depends on FFmpeg caption and font capabilities.

## Experience

1. Select a clip and choose **Edit text**, or tap its visible caption in the preview.
2. Open a focused editor with the current video frame at the top and controls below it. On a narrow phone use a full-screen route so the keyboard does not cover the preview; on larger screens a responsive side panel or sheet may be appropriate.
3. Update the preview immediately as text or style changes. Allow scrubbing to a useful frame within the clip; indicate when the caption is outside its visible time range.
4. Choose **Text**, **Style**, **Position**, or **Timing**. Keep one section visible at a time to avoid a long form.
5. **Save** applies the draft to the selected clip. **Cancel** discards the draft; system back follows the same rule, with a discard confirmation only when there are unsaved changes. Provide a separate, explicit **Apply style to all clips** action that does not overwrite their text or timing.

### Layout sketch

```text
  Back          Edit text                 Save
  ┌──────────────────────────────────────────┐
  │                                          │
  │             video preview                │
  │    · · · caption safe area · · ·         │
  │       ┌────────────────────────┐         │
  │       │       Title text       │         │
  │       │    Supporting line     │         │
  │       └────────────────────────┘         │
  └──────────────────────────────────────────┘
  ◀   00:04 ━━━━━━━●━━━━━━ 00:08   ▶

  [ Text ]  [ Style ]  [ Position ]  [ Timing ]
  ────────────────────────────────────────────
  Controls for the selected section
```

Maintain the video aspect ratio and fit the entire frame within the preview. The frame is the coordinate space for placement, not the surrounding card. Do not render editor guides or selection handles into the video.

## Visual design

The app UI should feel calm, readable, and consistent with the existing Material 3 theme. Use `context.colors` and `context.textTheme`, the app's existing spacing and shape tokens, and default Material component behavior. Use the documented 8 dp rhythm and existing small, medium, and large shape scale; do not introduce widget-local styling constants. Adapt to light and dark themes and large text.

| Element | Shape and hierarchy | Theme role / component |
| --- | --- | --- |
| Editor background | Flat, uncluttered surface | Scaffold background and `surface` |
| Preview frame | Large consistent rounded rectangle; video clipped to frame | Existing large shape; `surfaceContainerHighest` while loading |
| Toolbar | Simple top app bar, one prominent save action | `AppBar`, `FilledButton`, `onSurface` |
| Section selector | Compact, labeled segments with a clear selected state | Material segmented control; `primaryContainer` / `onPrimaryContainer` for selection |
| Controls | Flat groups with labels and enough space for touch | `surface`, `onSurface`, `onSurfaceVariant`, `outlineVariant` |
| Presets | Small rectangular preview cards with consistent rounded corners | `surface`; selected outline or selected tonal treatment from the theme |
| Warnings | Readable text with an icon; no decorative alarm colors | `error` / `onSurface` as appropriate, not color alone |

Use one strong primary action at a time. Use standard Material icons with accessible labels. Avoid additional accents, custom shadows, fake elevation, and decorative motion. Controls must remain usable with translated labels and enlarged system text.

## Caption appearance

### Presets

Provide three starting points. Preview each on the actual frame and label it in text as well as visually. Presets set font, size, text color, and backdrop; they do not change the words, placement, timing, or entrance. Applying one after customization should clearly replace the current style, and the user can reset to its defaults.

| Preset | Intent | Suggested treatment |
| --- | --- | --- |
| Clean | Minimal, suitable for calm footage | Readable light text with a subtle contrasting outline; no box |
| Soft backdrop | Default for varied footage | Light text on one dark, translucent backdrop surrounding both lines, with comfortable padding and restrained corners |
| Bold | High visibility | Heavier sans serif, strong contrast, and a compact dark backdrop |

Caption palette values are stored as output settings and may differ from the app's theme. Start with a small curated set of light and dark text/backdrop combinations. Show named swatches and a selection mark; never rely on color alone. Warn when the selected combination may be hard to read. Footage changes behind text, so even a valid text/backdrop pair cannot guarantee contrast when no backdrop is used; recommend an outline or backdrop in that case. Avoid assuming that a live contrast sample covers the whole clip.

Use one backdrop for the combined title and supporting line, sized to their content and bounded by the safe area. Keep a consistent internal gap and padding. If the export renderer cannot reproduce rounded corners or an outline consistently, choose a supported treatment in both preview and export instead of showing a misleading preview.

### Typography

- Offer a short list of bundled, licensed typefaces with distinct but restrained styles, such as a neutral sans serif, a softer sans serif, and a readable serif. Show each name in its own font. Confirm the actual font assets, weights, licensing, and renderer support before promising choices.
- Title uses a stronger weight than the supporting line. The supporting line remains comfortably legible, with an intentional gap rather than a second detached box.
- Provide one labeled size slider for the caption group, with a visible value, accessible increment/decrement, and reset. Scale title and supporting line together to preserve hierarchy. Express size relative to the video frame, so export resolution does not change the composition.
- Wrap based on measured glyph widths, not character count. Preserve explicit line breaks. Show a warning when content exceeds the supported region; do not silently discard text. Let the user shorten it or change size and placement.
- Check script coverage and shaping for supported languages. Test Cyrillic and mixed scripts, as well as emoji. If a glyph or shaping capability is unavailable in export, show a specific warning or offer a supported fallback; do not imply guaranteed emoji support.

### Suggested starting proportions

These are initial design targets for evaluation, not fixed app UI tokens: constrain the caption group to roughly 80% of frame width and keep a minimum inset of roughly 10% from frame edges. Tune on portrait, square, and landscape clips. Avoid shrinking text automatically below a readable minimum. Actual dimensions must use measured text, video dimensions, and the renderer's capabilities.

## Position and interaction

- Offer labeled top, center, and bottom placement shortcuts with small alignment icons. Keep the existing placement behavior available for old projects.
- Allow dragging the entire caption group within the frame. Store its anchor in normalized video coordinates so it survives preview resizing and output resolution changes. Clamp the complete measured group, including backdrop, inside the safe region; re-clamp after text, font, size, or aspect ratio changes.
- Show a subtle safe-area guide and selected bounding box only during editing. Snap to center and the three vertical shortcuts with a light visual guide. Do not obscure the text with handles.
- Provide a non-gesture alternative: position shortcuts and labeled horizontal/vertical adjustment controls with keyboard and screen-reader support. Include **Reset position**. Avoid ambiguous gesture-only controls.
- Position relative to the displayed video frame after fitting/cropping, not the screen. If the caption is too large to fit, show an actionable warning instead of hiding or clipping it.
- Safe areas reduce edge cropping; they cannot predict every social platform's interface. Avoid promising that all platform overlays will be avoided.

## Timing and motion

Retain the existing caption start/end range and entrance choices: none, fade, and slide. Label the range in time as well as visually. Keep the reading-time warning and explain which action helps, such as extending the visible duration or shortening the text.

For UI motion, prefer simple implicit Material transitions: a short fade or size transition when switching sections, a subtle selection change for preset cards, and standard route transitions. Target approximately 150–250 ms for small UI changes, using existing motion tokens where available. Do not animate the video frame or move controls under the user's finger. Respect the system's reduced-motion setting and make state changes immediate when animations are disabled.

Caption entrance is an explicit video-content choice, separate from UI motion and system accessibility preferences. Keep it off by default unless a selected template already specifies otherwise. Preview the same duration, easing, direction, opacity, and timing used by export. Do not add decorative loops or animated text by default.

## Clip list, duplicates, and ordering

### What needs investigation

The screenshot shows repeated filenames, including `20260719_144613.jpg` and `20260721_154728.jpg`. This alone does not establish whether they are accidental duplicates: the same image may intentionally occur at multiple points in the video, or separate files may share a name. Inspect the actual project, clip IDs, media IDs, source paths, timeline times, and import history before deciding why they appear. Do not delete or merge existing clips automatically.

The staged media selection already rejects repeated media IDs and offers custom, import, title, and file-date sorting. Its file-date sort currently uses file modification date, falling back to import date; it is not necessarily the photo's capture date. The timeline can contain distinct clip occurrences, and restoring a project reconstructs the staged selection by media ID. Check the interaction between that restoration, sorting, and timeline synchronization before reusing these operations for an existing edited project.

### Recommended list design

Replace the long list of nearly identical text cards with compact, scannable clip rows in sequence order. Use a small thumbnail, clip number, readable filename, and a secondary line for the time range or caption summary. Highlight the currently selected clip with a themed tonal selection state. Tapping a row selects and seeks to that occurrence; an accessible edit action opens its text editor. Retain the caption summary, including a localized empty state. Truncate long names visually but expose the complete name to accessibility and in details.

Above the list, show the clip count and a compact **Sort** menu. Use Material list tiles, `surface`, `onSurface`, `onSurfaceVariant`, `outlineVariant`, and the existing shape and spacing tokens. Avoid an additional row of large buttons. Keep the list virtualized for long projects, and keep the selected clip identifiable after a filter or sort. Provide distinct loading, empty, and inaccessible-media states.

### Duplicate review

- Distinguish a **clip occurrence** from its **source media**: occurrences have independent IDs, timing, captions, framing, and transitions, even when they use the same source. Display a small labeled repeated-source indicator where this is known, with a details action showing occurrence positions and times.
- Use an exact source/media identity as the first signal. Different IDs or paths may still refer to identical content; consider a content hash only after assessing cost and permission constraints. Matching names, dates, or thumbnails alone are possible matches, never proof. Avoid slow full-file hashing during scrolling or on the UI thread.
- Add an optional **Review repeated media** view grouping confirmed repeats and separately labeling possible matches. Show thumbnails, names, times, and per-occurrence edits so the user can decide. Make clear whether an action removes an occurrence from the timeline or removes a source from the library; never conflate them.
- Offer explicit removal of a selected occurrence with a clear description of its timing and edits, and undo where the timeline supports it. Preserve other occurrences. Do not provide bulk removal until grouping confidence and the effect on timing, transitions, and edits are clear. Intentionally repeating an image must remain possible.
- Investigate whether duplicates arise during import, staging, timeline synchronization, or restoration. Fix the confirmed source separately, with a regression test, without silently modifying existing projects.

### Sorting recommendation

Yes: provide a **Sort** menu, but distinguish sorting the list for finding clips from changing the video sequence. Default to **Timeline order**. For list-only sorting, offer filename A–Z / Z–A and date oldest / newest, with an explicit active label. Selecting one changes only the displayed rows; it does not move clips, change playback, or renumber timeline positions. Preserve selection by clip ID. Add a clear **Timeline order** option to return to playback order.

Use accurately labeled metadata. Offer **File modified date** only when it is available, and show **Date unavailable** for missing values; do not silently present import date as a photo date. Add **Capture date** only after the app reliably reads and persists that metadata with documented timezone and missing-date handling. Use a deterministic, stable tie-breaker such as the original timeline position and define a consistent position for missing values. If natural filename sorting is adopted, test numbered names and localized text; do not assume filename timestamps are trustworthy dates.

If users need to change the actual video order, expose a separate **Reorder sequence** flow. Explain that playback order and clip times can change, show a proposed order before applying, and support cancel and undo. First determine how marker-based timing, repeated media, transitions, captions, framing, and other clip-specific edits are preserved. Disable the operation or explain conflicts when the current timeline cannot be safely reordered. Do not route it directly through the staged selection's synchronization without verifying those semantics.

### Additional acceptance checks

- Repeated source media is identifiable without treating identical names as proof. An intentional repeat remains independent, including after save and restore; removal affects only the chosen occurrence and is reversible where supported.
- List-only sorting leaves timeline event order, timing, edits, and export unchanged. Selection stays on the same clip ID; timeline position remains clear even in a sorted list.
- Test equal names and dates, missing dates, duplicate media IDs, different files with the same name, identical files at different paths, and repeated occurrences with different captions and framing. Verify ascending and descending sorting, stable ties, and accurate date labels.
- If sequence reordering is added, verify a preview of changes, cancellation, undo, and preservation of edits and transition behavior, including marker-linked clips and project reload. Large lists remain responsive and accessible.

## State, rendering, and compatibility

- Keep feature UI as small composable widgets. A Riverpod ViewModel owns an immutable editing draft and typed user intents; widgets render state and forward actions. Use existing navigation conventions if a full-screen route is added.
- Extend the caption model with versioned or backward-compatible style and optional normalized position settings. Missing fields must retain the existing appearance and placement of saved projects; do not silently restyle them. Preset identity and explicit overrides should have predictable serialization and reset behavior.
- Keep a single resolved caption layout as the source for preview and export: selected font and weight, actual line breaks and metrics, anchor, size, backdrop bounds, color, and entrance state. Investigate differences in Flutter and FFmpeg font metrics, shaping, and alpha handling; use a shared rendering strategy or explicitly restrict features when parity cannot be achieved.
- Resolve bundled font paths on each supported platform. Check renderer capabilities before enabling features; surface actionable errors for unavailable filters, fonts, glyphs, or rendering failures.
- Limit expensive text layout and preview work during drag and slider updates. Do not perform file access or rendering in widget builds.
- Localize all labels, instructions, values, warnings, and accessibility descriptions in English, Norwegian, and Russian using `context.l10n`. Support long translations and text direction where relevant.

## Delivery sequence

1. Validate the visual direction with a static mockup and real portrait, square, and landscape frames, including the example in the request.
2. Specify and test the caption style model, font assets, measured layout, safe-area constraints, and migration of existing projects.
3. Build the focused editor and draft interactions; add preset, typography, color, position, and timing controls using Material 3 components.
4. Implement equivalent preview and export rendering, including supported backdrops and font handling. Disable or explain unsupported options rather than approximating silently.
5. Verify accessibility, localization, performance, and output parity before enabling the feature broadly.

## Acceptance checks

- A user can edit both lines, select a preset, change font, size and colors, position text without dragging, preview timing, save, cancel, reset, and apply style to other clips without replacing their content.
- Text stays inside the video safe area across supported aspect ratios and resizing; long text and short display times produce actionable warnings.
- Editing preview and rendered output agree on wrapping, placement, style, timing, and animation within a documented visual tolerance. Compare exported frames at the beginning, middle, and end of an entrance.
- Existing projects retain their previous appearance and timing after loading and saving. Test missing, unknown, and invalid serialized values.
- Cover representative light and dark footage, long text, empty fields, Cyrillic, mixed scripts, emoji and unavailable fonts or filters. Clearly communicate unsupported rendering.
- Test ViewModel state and serialization, layout boundaries, widget interactions, keyboard and screen-reader access, large text, reduced motion, and all supported locales. Check responsiveness and playback on a real device.
