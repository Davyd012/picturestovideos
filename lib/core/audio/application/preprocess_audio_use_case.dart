import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/application/audio_cache_signature_builder.dart';
import 'package:picturestovideos/core/audio/data/beat_map_cache_repository.dart';
import 'package:picturestovideos/core/audio/data/shared_preferences_beat_map_cache_repository.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/audio/domain/beat_map_cache_entry.dart';

final preprocessAudioUseCaseProvider = Provider<PreprocessAudioUseCase>(
  (ref) => PreprocessAudioUseCase(
    cacheRepository: ref.watch(beatMapCacheRepositoryProvider),
    signatureBuilder: ref.watch(audioCacheSignatureBuilderProvider),
  ),
);

class PreprocessAudioUseCase {
  const PreprocessAudioUseCase({
    required BeatMapCacheRepository cacheRepository,
    required AudioCacheSignatureBuilder signatureBuilder,
  }) : this._(
          cacheRepository,
          signatureBuilder,
        );

  const PreprocessAudioUseCase._(
    this._cacheRepository,
    this._signatureBuilder,
  );

  final BeatMapCacheRepository _cacheRepository;
  final AudioCacheSignatureBuilder _signatureBuilder;

  static const cacheVersion = 1;

  Future<BeatMap?> loadCachedBeatMap(AudioData audioData) async {
    final signature = _signatureBuilder.build(audioData);
    final entry = await _cacheRepository.load(audioSignature: signature);
    if (entry == null || entry.version != cacheVersion) {
      return null;
    }

    return entry.beatMap;
  }

  Future<void> saveBeatMap({
    required AudioData audioData,
    required BeatMap beatMap,
  }) {
    return _cacheRepository.save(
      BeatMapCacheEntry(
        version: cacheVersion,
        audioSignature: _signatureBuilder.build(audioData),
        beatMap: beatMap,
      ),
    );
  }

  Future<void> clear() {
    return _cacheRepository.clear();
  }
}
