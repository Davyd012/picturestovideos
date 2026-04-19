import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/event_execution.dart';

class EventSystemState {
  const EventSystemState({
    required this.events,
    required this.nextEventIndex,
    required this.executions,
  });

  const EventSystemState.initial()
      : events = const [],
        nextEventIndex = 0,
        executions = const [];

  final List<BeatEvent> events;
  final int nextEventIndex;
  final List<EventExecution> executions;

  bool get hasEvents => events.isNotEmpty;

  EventExecution? get lastExecution =>
      executions.isEmpty ? null : executions.last;
}
