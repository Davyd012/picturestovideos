import 'package:flutter/widgets.dart';
import 'package:picturestovideos/features/editor/editor_tab_state.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';

String editorTabLabel(BuildContext context, EditorTab tab) => switch (tab) {
  EditorTab.timeline => context.l10n.editorTimeline,
  EditorTab.clips => context.l10n.editorClips,
  EditorTab.markers => context.l10n.editorMarkers,
  EditorTab.tools => context.l10n.editorTools,
};
