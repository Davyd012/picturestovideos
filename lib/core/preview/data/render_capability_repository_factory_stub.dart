import 'package:picturestovideos/core/preview/data/render_capability_repository.dart';
import 'package:picturestovideos/core/preview/domain/render_capabilities.dart';

RenderCapabilityRepository createRenderCapabilityRepository() =>
    const _UnsupportedRenderCapabilityRepository();

class _UnsupportedRenderCapabilityRepository
    implements RenderCapabilityRepository {
  const _UnsupportedRenderCapabilityRepository();

  @override
  Future<RenderCapabilities> probe() async => RenderCapabilities(
    platformSupported: false,
    ffmpegAvailable: false,
    filters: const {},
    encoders: const {},
    muxers: const {},
    videoEncoder: '',
  );
}
