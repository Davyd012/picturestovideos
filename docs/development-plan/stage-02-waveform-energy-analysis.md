# Stage 02: Waveform And Energy Analysis

## Goal

Convert raw samples into time-based analysis frames.

## Scope

Build:

* frame chunking
* energy calculation per frame
* optional normalization
* analysis result model

## Output

```dart
class AudioFrame {
  final Duration time;
  final double energy;
}
```

## Logic

Suggested first pass:

* frame size: `1024`
* hop size: `512` or `1024`
* energy: sum of squared samples

## Architecture Notes

* keep frame analysis pure
* isolate-friendly service
* deterministic input and output

## Suggested Files

```text
lib/core/audio/domain/audio_frame.dart
lib/core/audio/application/frame_energy_analyzer.dart
lib/features/audio_analysis/audio_analysis_view_model.dart
lib/features/audio_analysis/audio_analysis_state.dart
```

## Done When

* `AudioData` converts into ordered `AudioFrame` list
* timestamps align with sample rate
* energy values are stable across repeated runs

## Tests

* pure unit tests for chunking
* pure unit tests for energy calculation
* fixture comparison tests
