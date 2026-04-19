import 'package:picturestovideos/core/timeline/domain/beat_event.dart';

class EventDispatchResult {
  const EventDispatchResult({
    required this.dispatchedEvents,
    required this.nextEventIndex,
  });

  final List<BeatEvent> dispatchedEvents;
  final int nextEventIndex;
}
