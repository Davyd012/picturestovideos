# Stage 08: Preprocessing And Cache

## Goal

Analyze once. Reuse many times.

## Scope

Build:

* beat map JSON cache
* cache invalidation rules
* optional background preprocessing
* import pipeline that reuses cached results

## Output

Example cache:

```json
{
  "version": 1,
  "audioHash": "abc123",
  "bpm": 120.0,
  "beats": [0.5, 1.0, 1.5]
}
```

## Architecture Notes

Prefer preprocessing for:

* stable sync
* lower CPU
* faster edit sessions

Keep cache format versioned.

## Optional Backend Path

If Flutter-only analysis is not accurate enough:

* keep repository contract
* swap analyzer implementation
* support external services later

Candidates:

* Python `librosa`
* Python `aubio`

## Suggested Files

```text
lib/core/audio/data/beat_map_cache_repository.dart
lib/core/audio/data/json_beat_map_cache_repository.dart
lib/core/audio/application/preprocess_audio_use_case.dart
```

## Done When

* analyzed files can skip repeated work
* cache survives app restart
* stale cache is invalidated safely

## Tests

* cache hit tests
* cache version mismatch tests
* audio hash mismatch tests
