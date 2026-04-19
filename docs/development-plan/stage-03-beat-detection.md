# Stage 03: Beat Detection

## Goal

Detect probable beat points from energy frames.

## Scope

Start simple:

* local peak detection
* moving average
* adaptive threshold

Do later:

* FFT
* onset detection
* backend-assisted analysis

## Output

```dart
class Beat {
  final Duration time;
  final double strength;
}
```

## Algorithm Order

1. peak over previous frame
2. threshold over rolling average
3. minimum interval debounce

This avoids noisy duplicate beats.

## Architecture Notes

* algorithm must be pure and testable
* tune with config object, not magic numbers in widgets

Example config fields:

* `sensitivity`
* `minBeatInterval`
* `movingAverageWindow`

## Suggested Files

```text
lib/core/audio/domain/beat.dart
lib/core/audio/domain/beat_detection_config.dart
lib/core/audio/application/beat_detector.dart
```

## Done When

* detector returns ordered beats
* duplicate close-range beats are filtered
* sensitivity is configurable

## Tests

* synthetic frame tests
* known-fixture beat timestamp tests
* false-positive regression tests
