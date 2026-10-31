import 'package:flutter/material.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';

abstract final class CaptionRenderColors {
  static Color text(CaptionSettings settings) =>
      settings.textColor == CaptionTextColor.white
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF000000);

  static Color backdrop(CaptionSettings settings) =>
      switch (settings.backdrop) {
        CaptionBackdrop.panel => const Color(0xB8000000),
        CaptionBackdrop.strongPanel => const Color(0xE0000000),
        _ => const Color(0xBF000000),
      };
}
