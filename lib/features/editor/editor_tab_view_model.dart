import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/features/editor/editor_tab_state.dart';

final editorTabViewModelProvider =
    NotifierProvider.autoDispose<EditorTabViewModel, EditorTab>(
      EditorTabViewModel.new,
    );

class EditorTabViewModel extends Notifier<EditorTab> {
  @override
  EditorTab build() => EditorTab.timeline;

  void tabSelected(EditorTab tab) {
    state = tab;
  }
}
