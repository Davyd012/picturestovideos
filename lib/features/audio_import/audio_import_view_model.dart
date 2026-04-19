import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/application/import_audio_use_case.dart';
import 'package:picturestovideos/features/audio_import/audio_import_state.dart';

final audioImportViewModelProvider = AsyncNotifierProvider.autoDispose<
    AudioImportViewModel, AudioImportState>(
  AudioImportViewModel.new,
);

class AudioImportViewModel extends AsyncNotifier<AudioImportState> {
  @override
  Future<AudioImportState> build() async {
    return const AudioImportState.initial();
  }

  Future<void> pickAudioFile() async {
    final previousState = state.value ?? const AudioImportState.initial();
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final result = await ref.read(importAudioUseCaseProvider).call();
      if (result == null) {
        return previousState;
      }

      return AudioImportState(
        source: result.source,
        audioData: result.audioData,
      );
    });
  }
}
