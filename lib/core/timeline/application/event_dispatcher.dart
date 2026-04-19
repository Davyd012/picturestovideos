import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/event_dispatch_result.dart';

final eventDispatcherProvider = Provider<EventDispatcher>(
  (ref) => const EventDispatcher(),
);

class EventDispatcher {
  const EventDispatcher();

  EventDispatchResult dispatch({
    required List<BeatEvent> events,
    required Duration currentTime,
    required int nextEventIndex,
    Duration tolerance = const Duration(milliseconds: 40),
  }) {
    if (nextEventIndex < 0) {
      throw ArgumentError.value(
        nextEventIndex,
        'nextEventIndex',
        'Next event index must not be negative.',
      );
    }

    if (events.isEmpty || nextEventIndex >= events.length) {
      return EventDispatchResult(
        dispatchedEvents: const [],
        nextEventIndex: events.length,
      );
    }

    final dispatchedEvents = <BeatEvent>[];
    var index = nextEventIndex;
    while (index < events.length) {
      final event = events[index];
      if (event.time > currentTime + tolerance) {
        break;
      }

      if ((event.time - currentTime).abs() <= tolerance ||
          event.time < currentTime - tolerance) {
        dispatchedEvents.add(event);
        index += 1;
        continue;
      }

      break;
    }

    return EventDispatchResult(
      dispatchedEvents: List.unmodifiable(dispatchedEvents),
      nextEventIndex: index,
    );
  }
}
