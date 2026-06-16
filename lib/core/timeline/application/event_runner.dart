import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/event_execution.dart';

final eventRunnerProvider = Provider<EventRunner>((ref) => const EventRunner());

class EventRunner {
  const EventRunner();

  static const _supportedTypes = {'marker', 'image', 'animation', 'effect'};

  EventExecution run({required BeatEvent event, required Duration executedAt}) {
    if (_supportedTypes.contains(event.type)) {
      return EventExecution(
        event: event,
        executedAt: executedAt,
        wasHandled: true,
        message: 'Handled ${event.type} event.',
      );
    }

    return EventExecution(
      event: event,
      executedAt: executedAt,
      wasHandled: false,
      message: 'Unsupported event type: ${event.type}.',
    );
  }
}
