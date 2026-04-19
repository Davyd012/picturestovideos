# Architecture

## Product Shape

This app should treat audio analysis as a domain problem, not a widget problem.

Preferred flow:

```text
data source -> repository -> analysis service -> immutable models -> playback coordinator -> UI
```

## Layers

### Domain

Pure models and logic.

Examples:

* `AudioData`
* `AudioFrame`
* `Beat`
* `BeatMap`
* `BeatEvent`
* `ProjectTimeline`

No Flutter imports.

### Data

Handles file access, decoding, persistence, and optional native or backend integration.

Examples:

* audio file picker adapter
* PCM decoder
* local JSON cache
* FFmpeg bridge

### Application

Orchestrates use cases.

Examples:

* import audio
* analyze waveform
* detect beats
* build beat map
* start synced playback
* dispatch timeline events

### Presentation

Thin screens and widgets.

Rules:

* widgets observe state
* widgets call intent methods
* widgets do not analyze audio

## Feature Split

```text
lib/
  core/
    audio/
      domain/
      data/
      application/
    timeline/
      domain/
      application/
  features/
    audio_import/
    audio_analysis/
    playback/
    timeline/
```

## ViewModel Plan

Use one ViewModel per feature boundary.

Examples:

* `AudioImportViewModel`
* `AudioAnalysisViewModel`
* `PlaybackViewModel`
* `TimelineViewModel`

Intent methods should be task-based:

* `pickAudioFile()`
* `analyzeAudio()`
* `startPlayback()`
* `pausePlayback()`
* `addEvent()`

## Repository Contracts

Start with interfaces:

```dart
abstract interface class AudioRepository {}
abstract interface class BeatAnalysisRepository {}
abstract interface class ProjectRepository {}
```

This keeps platform and backend choices swappable.

## Performance Rules

* heavy analysis off main isolate
* playback timing from player clock
* preprocessing preferred over repeated realtime analysis
* keep domain models immutable

## Testing Strategy

Prioritize:

1. unit tests for analysis math
2. unit tests for playback sync logic
3. provider tests for ViewModels
4. widget tests only after logic stabilizes
