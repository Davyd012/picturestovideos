import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/features/timeline/timeline_state.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';

void main() {
  test('buildProjectTimeline creates a project with serialized payload', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(timelineViewModelProvider.future);
    await container.read(timelineViewModelProvider.notifier).buildProjectTimeline(
          beatMap: const BeatMap(
            beats: [
              Beat(
                time: Duration(milliseconds: 200),
                strength: 1.5,
              ),
            ],
            bpm: 120,
            averageBeatInterval: Duration(milliseconds: 500),
          ),
          events: const [
            BeatEvent(
              time: Duration(milliseconds: 200),
              type: 'marker',
              payload: 'Beat 1',
            ),
          ],
        );

    final state = container.read(timelineViewModelProvider);

    expect(state, isA<AsyncData<TimelineState>>());
    expect(state.value?.hasProject, isTrue);
    expect(state.value?.project?.tracks.length, 1);
    expect(state.value?.serializedProject?['name'], 'Picture To Videos Project');
  });
}
