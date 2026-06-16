import 'package:picturestovideos/core/audio/domain/audio_marker_preset.dart';
import 'package:picturestovideos/core/media/domain/saved_image_asset.dart';

class HomeState {
  const HomeState({
    required this.audioPresets,
    required this.imageAssets,
    required this.isOpeningAudio,
    required this.statusMessage,
  });

  const HomeState.initial()
    : audioPresets = const [],
      imageAssets = const [],
      isOpeningAudio = false,
      statusMessage = null;

  final List<AudioMarkerPreset> audioPresets;
  final List<SavedImageAsset> imageAssets;
  final bool isOpeningAudio;
  final String? statusMessage;

  bool get hasSavedAudio => audioPresets.isNotEmpty;
  bool get hasSavedImages => imageAssets.isNotEmpty;
  bool get hasSavedMedia => hasSavedAudio || hasSavedImages;

  HomeState copyWith({
    List<AudioMarkerPreset>? audioPresets,
    List<SavedImageAsset>? imageAssets,
    bool? isOpeningAudio,
    String? statusMessage,
    bool clearStatusMessage = false,
  }) {
    return HomeState(
      audioPresets: audioPresets ?? this.audioPresets,
      imageAssets: imageAssets ?? this.imageAssets,
      isOpeningAudio: isOpeningAudio ?? this.isOpeningAudio,
      statusMessage: clearStatusMessage
          ? null
          : statusMessage ?? this.statusMessage,
    );
  }
}
