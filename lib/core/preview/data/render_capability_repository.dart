import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/preview/data/render_capability_repository_factory.dart'
    as capability_factory;
import 'package:picturestovideos/core/preview/domain/render_capabilities.dart';

final renderCapabilityRepositoryProvider = Provider<RenderCapabilityRepository>(
  (ref) => capability_factory.createRenderCapabilityRepository(),
);

final renderCapabilitiesProvider =
    FutureProvider.autoDispose<RenderCapabilities>(
      (ref) => ref.read(renderCapabilityRepositoryProvider).probe(),
    );

abstract interface class RenderCapabilityRepository {
  /// Probes the actual FFmpeg build used by the active renderer.
  Future<RenderCapabilities> probe();
}
