import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/core/timeline/application/dispatch_events_use_case.dart';
import 'package:picturestovideos/core/timeline/application/run_event_use_case.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/event_execution.dart';
import 'package:picturestovideos/features/event_system/event_system_state.dart';

final eventSystemViewModelProvider =
    AsyncNotifierProvider<EventSystemViewModel, EventSystemState>(
      EventSystemViewModel.new,
    );

class EventSystemViewModel extends AsyncNotifier<EventSystemState> {
  static const _tag = 'EventSystemViewModel';

  @override
  Future<EventSystemState> build() async {
    ref.read(appLoggerProvider).info(_tag, 'Initializing event system state');
    return const EventSystemState.initial();
  }

  Future<void> loadMarkerEventsFromBeatMap(BeatMap beatMap) async {
    ref
        .read(appLoggerProvider)
        .info(_tag, 'Loading marker events from ${beatMap.beats.length} beats');
    final markerEvents = [
      for (var index = 0; index < beatMap.beats.length; index++)
        BeatEvent(
          time: beatMap.beats[index].time,
          type: 'marker',
          payload: 'Beat ${index + 1}',
        ),
    ];

    loadMarkerEvents(markerEvents);
  }

  void loadMarkerEvents(List<BeatEvent> markerEvents) {
    state = AsyncData(
      EventSystemState(
        events: List.unmodifiable(markerEvents),
        nextEventIndex: 0,
        executions: const [],
      ),
    );
  }

  void reset() {
    state = const AsyncData(EventSystemState.initial());
  }

  Future<void> dispatchForPlaybackTime(Duration currentTime) async {
    final previousState = state.value ?? const EventSystemState.initial();
    if (!previousState.hasEvents) {
      return;
    }

    ref
        .read(appLoggerProvider)
        .debug(_tag, 'Dispatching for ${currentTime.inMilliseconds} ms');

    final dispatchResult = ref
        .read(dispatchEventsUseCaseProvider)
        .call(
          events: previousState.events,
          currentTime: currentTime,
          nextEventIndex: previousState.nextEventIndex,
        );
    if (dispatchResult.dispatchedEvents.isEmpty) {
      return;
    }

    final executions = [
      ...previousState.executions,
      ..._runEvents(
        events: dispatchResult.dispatchedEvents,
        currentTime: currentTime,
      ),
    ];

    state = AsyncData(
      EventSystemState(
        events: previousState.events,
        nextEventIndex: dispatchResult.nextEventIndex,
        executions: List.unmodifiable(executions),
      ),
    );
  }

  List<EventExecution> _runEvents({
    required List<BeatEvent> events,
    required Duration currentTime,
  }) {
    return [
      for (final event in events)
        ref
            .read(runEventUseCaseProvider)
            .call(event: event, executedAt: currentTime),
    ];
  }
}
