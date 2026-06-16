import 'package:picturestovideos/core/timeline/domain/beat_event.dart';

class TimelineTrack {
  const TimelineTrack({
    required this.id,
    required this.name,
    required this.events,
  });

  final String id;
  final String name;
  final List<BeatEvent> events;

  TimelineTrack copyWith({String? id, String? name, List<BeatEvent>? events}) {
    return TimelineTrack(
      id: id ?? this.id,
      name: name ?? this.name,
      events: events ?? this.events,
    );
  }
}
