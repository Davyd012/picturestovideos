/// Persisted marker identity and its optional image boundary association.
class TimelineMarkerPayload {
  const TimelineMarkerPayload({required this.id, this.linkedClipId, this.name});

  final String id;
  final String? linkedClipId;
  final String? name;

  Map<String, Object?> toJson() => {
    'kind': 'timeline-marker',
    'id': id,
    'linkedClipId': linkedClipId,
    'name': name,
  };

  factory TimelineMarkerPayload.fromJson(Map<String, Object?> json) =>
      TimelineMarkerPayload(
        id: json['id'] as String? ?? '',
        linkedClipId: json['linkedClipId'] as String?,
        name: json['name'] as String?,
      );

  TimelineMarkerPayload copyWith({String? linkedClipId, bool unlink = false}) =>
      TimelineMarkerPayload(
        id: id,
        linkedClipId: unlink ? null : linkedClipId ?? this.linkedClipId,
        name: name,
      );
}
