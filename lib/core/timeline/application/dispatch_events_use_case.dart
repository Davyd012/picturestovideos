import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/timeline/application/event_dispatcher.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/event_dispatch_result.dart';

final dispatchEventsUseCaseProvider = Provider<DispatchEventsUseCase>(
  (ref) => DispatchEventsUseCase(
    eventDispatcher: ref.watch(eventDispatcherProvider),
  ),
);

class DispatchEventsUseCase {
  const DispatchEventsUseCase({
    required EventDispatcher eventDispatcher,
  }) : this._(eventDispatcher);

  const DispatchEventsUseCase._(this._eventDispatcher);

  final EventDispatcher _eventDispatcher;

  EventDispatchResult call({
    required List<BeatEvent> events,
    required Duration currentTime,
    required int nextEventIndex,
    Duration tolerance = const Duration(milliseconds: 40),
  }) {
    return _eventDispatcher.dispatch(
      events: events,
      currentTime: currentTime,
      nextEventIndex: nextEventIndex,
      tolerance: tolerance,
    );
  }
}
