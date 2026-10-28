import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/timeline/application/suggest_clip_boundaries_use_case.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/sequence_pacing.dart';

void main() {
  const suggest = SuggestClipBoundariesUseCase();
  const beatMap = BeatMap(
    beats: [
      Beat(time: Duration(seconds: 3), strength: 0.2),
      Beat(time: Duration(seconds: 4), strength: 1),
    ],
    bpm: 120,
    averageBeatInterval: Duration(milliseconds: 500),
  );
  test('selects strong nearby markers, not every beat', () {
    final markers = [
      for (var i = 1; i < 14; i++)
        BeatEvent(
          time: Duration(milliseconds: i * 500),
          type: 'marker',
        ),
    ];
    final result = suggest(
      photoCount: 2,
      beatMap: beatMap,
      markers: markers,
      pacing: SequencePacing.balanced,
    );
    expect(result, [
      Duration.zero,
      const Duration(seconds: 4),
      const Duration(seconds: 7),
    ]);
  });
  test('uses all photos and trims suggestion to shorter music', () {
    final result = suggest(
      photoCount: 4,
      beatMap: beatMap,
      markers: const [],
      pacing: SequencePacing.relaxed,
      audioDuration: const Duration(seconds: 8),
    );
    expect(result, [
      Duration.zero,
      const Duration(seconds: 2),
      const Duration(seconds: 4),
      const Duration(seconds: 6),
      const Duration(seconds: 8),
    ]);
  });
  test('pacing changes suggestion length with sparse or absent markers', () {
    final energetic = suggest(
      photoCount: 2,
      beatMap: beatMap,
      markers: const [],
      pacing: SequencePacing.energetic,
    );
    final relaxed = suggest(
      photoCount: 2,
      beatMap: beatMap,
      markers: const [],
      pacing: SequencePacing.relaxed,
    );
    expect(energetic.last, const Duration(seconds: 5));
    expect(relaxed.last, const Duration(seconds: 10));
    expect(
      suggest(
        photoCount: 0,
        beatMap: beatMap,
        markers: const [],
        pacing: SequencePacing.balanced,
      ),
      isEmpty,
    );
  });
}
