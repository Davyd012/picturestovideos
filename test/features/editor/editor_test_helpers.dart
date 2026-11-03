import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/preview/data/render_capability_repository.dart';
import 'package:picturestovideos/core/preview/domain/render_capabilities.dart';

ProviderContainer createEditorTestContainer() => ProviderContainer(
  overrides: [
    renderCapabilitiesProvider.overrideWith(
      (ref) async => RenderCapabilities(
        platformSupported: true,
        ffmpegAvailable: true,
        filters: const {'zoompan', 'xfade', 'drawtext', 'drawbox'},
        encoders: const {},
        muxers: const {},
        videoEncoder: 'test',
        fontPath: 'test-font',
      ),
    ),
  ],
);
