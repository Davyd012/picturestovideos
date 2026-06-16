import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/data/shared_preferences_audio_marker_preset_repository.dart';
import 'package:picturestovideos/core/audio/domain/audio_marker_preset.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/core/media/data/shared_preferences_saved_image_asset_repository.dart';
import 'package:picturestovideos/features/audio_import/audio_import_view_model.dart';
import 'package:picturestovideos/features/home/home_state.dart';

final homeViewModelProvider =
    AsyncNotifierProvider.autoDispose<HomeViewModel, HomeState>(
      HomeViewModel.new,
    );

class HomeViewModel extends AsyncNotifier<HomeState> {
  static const _tag = 'HomeViewModel';

  @override
  Future<HomeState> build() async {
    ref.read(appLoggerProvider).info(_tag, 'Loading saved media');
    return _loadSavedMedia();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadSavedMedia);
  }

  Future<bool> openSavedAudio(AudioMarkerPreset preset) async {
    final currentState = state.value ?? const HomeState.initial();
    final sourcePath = preset.sourcePath?.trim();
    if (sourcePath == null || sourcePath.isEmpty) {
      state = AsyncData(
        currentState.copyWith(
          statusMessage: 'This saved audio does not have a file path.',
        ),
      );
      return false;
    }

    final file = File(sourcePath);
    if (!await file.exists()) {
      state = AsyncData(
        currentState.copyWith(
          statusMessage: 'No audio file exists at $sourcePath.',
        ),
      );
      return false;
    }

    state = AsyncData(
      currentState.copyWith(isOpeningAudio: true, clearStatusMessage: true),
    );
    try {
      await ref
          .read(audioImportViewModelProvider.notifier)
          .importAudioFromPath(sourcePath);
      state = AsyncData(
        (state.value ?? currentState).copyWith(isOpeningAudio: false),
      );
      return true;
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .error(_tag, error, stackTrace, message: 'Saved audio open failed');
      state = AsyncData(
        currentState.copyWith(
          isOpeningAudio: false,
          statusMessage: error.toString(),
        ),
      );
      return false;
    }
  }

  Future<HomeState> _loadSavedMedia() async {
    final audioPresets = [
      ...await ref.read(audioMarkerPresetRepositoryProvider).loadAll(),
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final imageAssets = [
      ...await ref.read(savedImageAssetRepositoryProvider).loadAll(),
    ]..sort((a, b) => b.importedOn.compareTo(a.importedOn));
    return HomeState(
      audioPresets: List.unmodifiable(audioPresets),
      imageAssets: List.unmodifiable(imageAssets),
      isOpeningAudio: false,
      statusMessage: null,
    );
  }
}
