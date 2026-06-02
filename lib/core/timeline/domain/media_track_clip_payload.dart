class MediaTrackClipPayload {
  const MediaTrackClipPayload({
    required this.mediaId,
    required this.title,
    required this.tagline,
    required this.start,
    required this.end,
    required this.sourcePath,
  });

  final String mediaId;
  final String title;
  final String tagline;
  final Duration start;
  final Duration end;
  final String sourcePath;

  Map<String, Object?> toJson() {
    return {
      'kind': 'media-track-clip',
      'mediaId': mediaId,
      'title': title,
      'tagline': tagline,
      'startMs': start.inMilliseconds,
      'endMs': end.inMilliseconds,
      'sourcePath': sourcePath,
    };
  }

  factory MediaTrackClipPayload.fromJson(Map<String, Object?> json) {
    return MediaTrackClipPayload(
      mediaId: json['mediaId']! as String,
      title: json['title']! as String,
      tagline: json['tagline']! as String,
      start: Duration(milliseconds: json['startMs']! as int),
      end: Duration(milliseconds: json['endMs']! as int),
      sourcePath: json['sourcePath']! as String,
    );
  }

  MediaTrackClipPayload copyWith({
    String? mediaId,
    String? title,
    String? tagline,
    Duration? start,
    Duration? end,
    String? sourcePath,
  }) {
    return MediaTrackClipPayload(
      mediaId: mediaId ?? this.mediaId,
      title: title ?? this.title,
      tagline: tagline ?? this.tagline,
      start: start ?? this.start,
      end: end ?? this.end,
      sourcePath: sourcePath ?? this.sourcePath,
    );
  }
}
