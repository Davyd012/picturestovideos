# Stage 06: Event System

## Goal

Translate beat timing into domain events the app can execute.

## Scope

Build:

* event model
* event dispatcher
* event handlers by type
* event execution logging

## Output

```dart
class BeatEvent {
  final Duration time;
  final String type;
  final Object? payload;
}
```

Prefer typed event hierarchies later if event count grows.

## Architecture Notes

Separate:

* scheduling
* dispatching
* side effects

This keeps future editor and export logic stable.

## Suggested Event Types

* image swap
* transform animation
* transition effect
* marker

## Suggested Files

```text
lib/core/timeline/domain/beat_event.dart
lib/core/timeline/application/event_dispatcher.dart
lib/core/timeline/application/event_runner.dart
```

## Done When

* beat-aligned events can be registered
* due events fire exactly once
* event payloads are validated

## Tests

* dispatch order tests
* duplicate firing tests
* unknown type handling tests
