import 'package:flutter/material.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/features/editor/widgets/clip_caption_list.dart';

class ClipCaptionsEditor extends StatelessWidget {
  const ClipCaptionsEditor({
    required this.clips,
    required this.onEditClip,
    this.onSelectClip,
    this.onRemoveClip,
    this.onMoveClip,
    this.onReorderClip,
    super.key,
  });

  final List<MediaTrackClipPayload> clips;
  final ValueChanged<MediaTrackClipPayload> onEditClip;
  final ValueChanged<MediaTrackClipPayload>? onSelectClip;
  final ValueChanged<String>? onRemoveClip;
  final bool Function(String clipId, int position)? onMoveClip;
  final bool Function(String clipId, int position)? onReorderClip;

  @override
  Widget build(BuildContext context) => ClipCaptionList(
    clips: clips,
    onEdit: (clip, _) => onEditClip(clip),
    onSelect: onSelectClip,
    onRemove: onRemoveClip,
    onMove: onMoveClip,
    onReorder: onReorderClip,
  );
}
