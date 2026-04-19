import 'package:picturestovideos/core/timeline/domain/beat_event.dart';

class EventExecution {
  const EventExecution({
    required this.event,
    required this.executedAt,
    required this.wasHandled,
    required this.message,
  });

  final BeatEvent event;
  final Duration executedAt;
  final bool wasHandled;
  final String message;
}
