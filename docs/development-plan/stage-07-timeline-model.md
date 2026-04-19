# Stage 07: Timeline Model

## Goal

Define the project structure the future editor will manipulate.

## Scope

Build immutable timeline models for:

* project
* tracks
* clips or assets
* beat-linked events

## Output

```dart
class TimelineTrack {
  final List<BeatEvent> events;
}

class Project {
  final BeatMap beatMap;
  final List<TimelineTrack> tracks;
}
```

## Architecture Notes

Design for editing later:

* add event
* move event
* remove event
* serialize project

Do not bury project shape inside UI state.

## Suggested Files

```text
lib/core/timeline/domain/timeline_track.dart
lib/core/timeline/domain/project_timeline.dart
lib/core/timeline/application/project_serializer.dart
lib/features/timeline/timeline_view_model.dart
```

## Done When

* project model persists cleanly
* tracks are independent
* timeline supports future editor operations

## Tests

* serialization round-trip tests
* immutable update tests
* validation tests for overlapping or invalid events
