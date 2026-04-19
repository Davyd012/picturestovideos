# Development Plan

Audio first. UI later.

## Goal

Build a Flutter app that turns audio timing into a stable event-driven timeline for image, animation, and export workflows.

Core pipeline:

```text
Audio source -> Decode -> Frame analysis -> Beat detection -> Beat map -> Playback sync -> Timeline events -> UI/editor/export
```

## Architecture Direction

Follow repo rules:

* Riverpod + ViewModel
* Feature-first folders
* Business logic outside widgets
* Test logic before UI polish

Suggested app structure:

```text
lib/
  core/
    audio/
      domain/
      application/
      data/
    timeline/
      domain/
      application/
  features/
    audio_import/
    audio_analysis/
    playback/
    timeline/
    export/
  shared/
```

## Delivery Order

1. Stage 01: Audio ingestion
2. Stage 02: Waveform and energy analysis
3. Stage 03: Beat detection
4. Stage 04: Beat map
5. Stage 05: Playback engine
6. Stage 06: Event system
7. Stage 07: Timeline model
8. Stage 08: Preprocessing and caching

## MVP Gates

* V1: Load audio, decode samples, print beats
* V2: Play audio and trigger logs on beat
* V3: Trigger simple visual change on beat
* V4: Persist project timeline data

## Definition Of Done

Each stage should include:

* domain models
* repository contracts
* Riverpod providers
* unit tests for logic
* fixture-based sample data

Read next:

* [Architecture](./architecture.md)
* [Stage 01](./stage-01-audio-ingestion.md)
