# Stage 05: Playback Engine

## Goal

Synchronize playback time with beat data in realtime.

## Scope

Build:

* audio playback adapter
* current-time stream from player clock
* indexed beat traversal
* tolerance-based trigger logic

## Core Rule

Never scan the full beat list every tick.

Use:

* current beat index
* forward-only progression
* small tolerance window

## Architecture Notes

Playback coordination belongs in application logic, not UI.

Possible split:

* player adapter
* playback coordinator
* ViewModel

## Suggested Files

```text
lib/core/audio/data/audio_player_repository.dart
lib/core/audio/application/playback_coordinator.dart
lib/features/playback/playback_view_model.dart
lib/features/playback/playback_state.dart
```

## Done When

* playback time comes from audio engine
* beats trigger once
* pause and resume keep sync

## Tests

* fake clock tests
* beat index progression tests
* tolerance boundary tests
