# Stage 04: Beat Map

## Goal

Turn detected beats into a reusable song timeline model.

## Scope

Build:

* `BeatMap`
* BPM estimation
* average interval metrics
* optional confidence summary

## Output

```dart
class BeatMap {
  final List<Beat> beats;
  final double bpm;
}
```

## Architecture Notes

`BeatMap` is the contract between analysis and playback.

Everything later should depend on `BeatMap`, not raw analysis frames.

## Suggested Files

```text
lib/core/audio/domain/beat_map.dart
lib/core/audio/application/beat_map_builder.dart
```

## Done When

* beat map builds from beat list
* BPM is computed from stable intervals
* output can be serialized

## Tests

* BPM calculation tests
* serialization tests
* edge cases for short or sparse tracks
