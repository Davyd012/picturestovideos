import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/features/editor/widgets/clip_caption_list.dart';

void main() {
  final first = _entry('clip-1', 'same.jpg', 0, DateTime(2026, 1, 2));
  final second = _entry('clip-2', 'same.jpg', 1, DateTime(2026, 1, 2));
  final third = _entry('clip-3', 'alpha.jpg', 2, null);
  final newestEntry = _entry('clip-4', 'omega.jpg', 3, DateTime(2026, 3, 4));

  test('filename sorting is stable and retains timeline positions', () {
    final ascending = sortClipCaptionEntries([
      first,
      second,
      third,
    ], ClipCaptionSort.nameAscending);
    expect(ascending.map((entry) => entry.clip.clipId), [
      'clip-3',
      'clip-1',
      'clip-2',
    ]);
    expect(ascending.map((entry) => entry.timelineIndex), [2, 0, 1]);
    final descending = sortClipCaptionEntries([
      first,
      second,
      third,
    ], ClipCaptionSort.nameDescending);
    expect(descending.map((entry) => entry.clip.clipId), [
      'clip-1',
      'clip-2',
      'clip-3',
    ]);
  });

  test('date sorting keeps missing dates last and ties in timeline order', () {
    final oldest = sortClipCaptionEntries([
      newestEntry,
      third,
      second,
      first,
    ], ClipCaptionSort.modifiedOldest);
    expect(oldest.map((entry) => entry.clip.clipId), [
      'clip-1',
      'clip-2',
      'clip-4',
      'clip-3',
    ]);
    final newestSorted = sortClipCaptionEntries([
      third,
      second,
      first,
      newestEntry,
    ], ClipCaptionSort.modifiedNewest);
    expect(newestSorted.map((entry) => entry.clip.clipId), [
      'clip-4',
      'clip-1',
      'clip-2',
      'clip-3',
    ]);
  });

  test(
    'timeline sort preserves occurrence order regardless of input order',
    () {
      final result = sortClipCaptionEntries([
        third,
        first,
        second,
      ], ClipCaptionSort.timeline);
      expect(result.map((entry) => entry.timelineIndex), [0, 1, 2]);
    },
  );

  test('repeated source occurrences serialize independently', () {
    final firstClip = first.clip.copyWith(
      caption: 'First moment',
      captionSettings: const CaptionSettings(
        placement: CaptionPlacement.top,
        startFraction: 0.1,
        endFraction: 0.6,
      ),
    );
    final secondClip = second.clip.copyWith(
      caption: 'Return',
      captionSettings: const CaptionSettings(
        placement: CaptionPlacement.bottom,
        startFraction: 0.4,
        endFraction: 1,
      ),
    );
    final restoredFirst = MediaTrackClipPayload.fromJson(firstClip.toJson());
    final restoredSecond = MediaTrackClipPayload.fromJson(secondClip.toJson());
    expect(restoredFirst.mediaId, restoredSecond.mediaId);
    expect(restoredFirst.clipId, isNot(restoredSecond.clipId));
    expect(restoredFirst.caption, 'First moment');
    expect(restoredSecond.caption, 'Return');
    expect(restoredFirst.captionSettings.placement, CaptionPlacement.top);
    expect(restoredSecond.captionSettings.placement, CaptionPlacement.bottom);
  });
}

ClipCaptionListEntry _entry(
  String clipId,
  String title,
  int index,
  DateTime? modifiedAt,
) => ClipCaptionListEntry(
  clip: MediaTrackClipPayload(
    clipId: clipId,
    mediaId: 'shared-source',
    title: title,
    tagline: '',
    start: Duration(seconds: index * 3),
    end: Duration(seconds: (index + 1) * 3),
    sourcePath: '',
    imageFit: VideoTemplateImageFit.cover,
  ),
  timelineIndex: index,
  modifiedAt: modifiedAt,
);
