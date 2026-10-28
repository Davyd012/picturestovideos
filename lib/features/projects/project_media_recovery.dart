import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/data/device_audio_repository.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/library/image_import_repository.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';

class MissingProjectMedia {
  const MissingProjectMedia({
    required this.id,
    required this.path,
    required this.isAudio,
  });
  final String id;
  final String path;
  final bool isAudio;
}

final missingProjectMediaProvider = FutureProvider.autoDispose
    .family<List<MissingProjectMedia>, ProjectTimeline>((ref, project) async {
      final missing = <MissingProjectMedia>[];
      final audio = project.audioSourcePath;
      if (audio != null && audio.isNotEmpty && !await File(audio).exists()) {
        missing.add(MissingProjectMedia(id: '', path: audio, isAudio: true));
      }
      final seen = <String>{};
      for (final track in project.tracks) {
        if (track.id != 'track-media') continue;
        for (final event in track.events) {
          final clip = event.payload;
          if (clip is MediaTrackClipPayload &&
              seen.add(clip.mediaId) &&
              (clip.sourcePath.isEmpty ||
                  !await File(clip.sourcePath).exists())) {
            missing.add(
              MissingProjectMedia(
                id: clip.mediaId,
                path: clip.sourcePath,
                isAudio: false,
              ),
            );
          }
        }
      }
      return List.unmodifiable(missing);
    });

final projectMediaRecoveryProvider = Provider<ProjectMediaRecovery>(
  (ref) => ProjectMediaRecovery(ref),
);

class ProjectMediaRecovery {
  const ProjectMediaRecovery(this.ref);
  final Ref ref;

  Future<bool> relink(
    ProjectTimeline project,
    MissingProjectMedia missing,
  ) async {
    final String? path;
    if (missing.isAudio) {
      path = (await ref.read(audioFilePickerProvider).pickSongFile())?.path;
    } else {
      final files = await ref.read(imageFilePickerProvider).pickImageFiles();
      path = files.isEmpty ? null : files.first.path;
    }
    if (path == null) return false;
    if (path.isEmpty || !await File(path).exists()) {
      throw FileSystemException('Selected file is unavailable', path);
    }
    final timeline = ref.read(timelineViewModelProvider.notifier);
    final current = ref.read(timelineViewModelProvider).asData?.value.project;
    if (current == null || current.id != project.id) return false;
    final updated = missing.isAudio
        ? current.copyWith(audioSourcePath: path)
        : current.copyWith(
            tracks: [
              for (final track in current.tracks)
                if (track.id != 'track-media')
                  track
                else
                  track.copyWith(
                    events: [
                      for (final event in track.events)
                        if (event.payload is MediaTrackClipPayload &&
                            (event.payload as MediaTrackClipPayload).mediaId ==
                                missing.id)
                          BeatEvent(
                            time: event.time,
                            type: event.type,
                            payload: (event.payload as MediaTrackClipPayload)
                                .copyWith(sourcePath: path),
                          )
                        else
                          event,
                    ],
                  ),
            ],
          );
    if (!missing.isAudio) {
      ref
          .read(editorMediaSelectionViewModelProvider.notifier)
          .restoreProject(updated);
    }
    timeline.projectMediaRelinked(updated);
    return true;
  }
}
