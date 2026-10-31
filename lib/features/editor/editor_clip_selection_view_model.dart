import 'package:flutter_riverpod/flutter_riverpod.dart';

final editorClipSelectionViewModelProvider =
    NotifierProvider<EditorClipSelectionViewModel, EditorClipSelectionState>(
      EditorClipSelectionViewModel.new,
    );

class EditorClipSelectionState {
  const EditorClipSelectionState({
    this.selectedClipId,
    this.sortIndex = 0,
    this.reorderMode = false,
  });

  final String? selectedClipId;
  final int sortIndex;
  final bool reorderMode;

  EditorClipSelectionState copyWith({
    String? selectedClipId,
    bool clearSelectedClip = false,
    int? sortIndex,
    bool? reorderMode,
  }) => EditorClipSelectionState(
    selectedClipId: clearSelectedClip
        ? null
        : selectedClipId ?? this.selectedClipId,
    sortIndex: sortIndex ?? this.sortIndex,
    reorderMode: reorderMode ?? this.reorderMode,
  );
}

class EditorClipSelectionViewModel extends Notifier<EditorClipSelectionState> {
  @override
  EditorClipSelectionState build() => const EditorClipSelectionState();

  void clipSelected(String? clipId) {
    state = state.copyWith(
      selectedClipId: clipId,
      clearSelectedClip: clipId == null,
    );
  }

  void sortSelected(int index) {
    state = state.copyWith(
      sortIndex: index,
      reorderMode: index == 0 ? null : false,
    );
  }

  void reorderModeToggled() {
    state = state.copyWith(reorderMode: !state.reorderMode);
  }
}
