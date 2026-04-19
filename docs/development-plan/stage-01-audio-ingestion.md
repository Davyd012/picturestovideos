# Stage 01: Audio Ingestion

## Goal

Load an audio file and decode it into sample data the rest of the system can use.

## Scope

Build:

* file selection flow
* audio metadata loading
* PCM or normalized sample extraction
* error handling for unsupported files

## Output

```dart
class AudioData {
  final List<double> samples;
  final int sampleRate;
  final Duration duration;
}
```

## Architecture Notes

* repository owns file decoding
* ViewModel only coordinates import state
* no waveform UI required

## Suggested Files

```text
lib/core/audio/domain/audio_data.dart
lib/core/audio/domain/audio_source.dart
lib/core/audio/data/audio_repository.dart
lib/core/audio/data/device_audio_repository.dart
lib/features/audio_import/audio_import_view_model.dart
lib/features/audio_import/audio_import_state.dart
```

## Dependencies To Evaluate

* `just_audio`
* `ffmpeg_kit_flutter`
* `file_picker`

Keep decoder behind an interface.

## Done When

* user can select audio
* app decodes file into `AudioData`
* sample rate and duration are correct
* failures return typed errors

## Tests

* repository tests with fixture files
* ViewModel success and failure paths
