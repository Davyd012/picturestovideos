import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/features/event_system/event_system_state.dart';
import 'package:picturestovideos/features/event_system/event_system_view_model.dart';

void main() {
  test('loads marker events from beat map and dispatches once', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(eventSystemViewModelProvider.future);
    await container.read(eventSystemViewModelProvider.notifier).loadMarkerEventsFromBeatMap(
          const BeatMap(
            beats: [
              Beat(
                time: Duration(milliseconds: 200),
                strength: 1.5,
              ),
              Beat(
                time: Duration(milliseconds: 500),
                strength: 1.7,
              ),
            ],
            bpm: 120,
            averageBeatInterval: Duration(milliseconds: 500),
          ),
        );
    await container.read(eventSystemViewModelProvider.notifier).dispatchForPlaybackTime(
          const Duration(milliseconds: 220),
        );

    final state = container.read(eventSystemViewModelProvider);

    expect(state, isA<AsyncData<EventSystemState>>());
    expect(state.value?.events.length, 2);
    expect(state.value?.executions.length, 1);
    expect(state.value?.nextEventIndex, 1);
    expect(state.value?.lastExecution?.wasHandled, isTrue);
  });
}
