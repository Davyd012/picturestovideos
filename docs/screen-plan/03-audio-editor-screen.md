# Audio Editor Screen

## Priority

Build this third.

## Route

* `/projects/audio-editor`

## UI Reference

* `ADJUST_EDIT_AUDIO_SCREEN.html`

## Purpose

Main project workspace for preview, timeline editing, and beat-aware control.

## Core UI Areas

* preview player
* transport controls
* timeline toolbar
* track canvas
* beat markers

## Flutter File Target

Suggested start:

* `lib/features/editor/audio_editor_screen.dart`
* `lib/features/editor/widgets/`

## Notes

This should consume:

* `BeatMap`
* `ProjectTimeline`
* playback sync state
* event system state
