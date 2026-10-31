import 'package:picturestovideos/core/templates/domain/video_template.dart';

enum CaptionPlacement { bottom, center, top }

enum CaptionEntrance { none, fade, slide }

enum CaptionStylePreset { clean, softBackdrop, bold }

enum CaptionTextColor { white, black }

enum CaptionBackdrop { legacy, none, panel, strongPanel }

class CaptionSettings {
  const CaptionSettings({
    this.placement,
    this.entrance = CaptionEntrance.none,
    this.startFraction = 0,
    this.endFraction = 1,
    this.preset,
    this.sizeScale = 1,
    this.textColor = CaptionTextColor.white,
    this.backdrop = CaptionBackdrop.legacy,
  }) : assert(
         startFraction >= 0 && startFraction < endFraction && endFraction <= 1,
       );
  final CaptionPlacement? placement;
  final CaptionEntrance entrance;
  final double startFraction;
  final double endFraction;
  final CaptionStylePreset? preset;
  final double sizeScale;
  final CaptionTextColor textColor;
  final CaptionBackdrop backdrop;

  CaptionPlacement placementFor(VideoTemplate template) =>
      placement ??
      switch (template.textPlacement) {
        VideoTemplateTextPlacement.center => CaptionPlacement.center,
        _ => CaptionPlacement.bottom,
      };

  Map<String, Object?> toJson() => {
    'placement': placement?.name,
    'entrance': entrance.name,
    'startFraction': startFraction,
    'endFraction': endFraction,
    'preset': preset?.name,
    'sizeScale': sizeScale,
    'textColor': textColor.name,
    'backdrop': backdrop.name,
  };
  factory CaptionSettings.fromJson(Object? json) {
    if (json is! Map) return const CaptionSettings();
    final start = ((json['startFraction'] as num?)?.toDouble() ?? 0).clamp(
      0.0,
      1.0,
    );
    final end = ((json['endFraction'] as num?)?.toDouble() ?? 1).clamp(
      0.0,
      1.0,
    );
    return CaptionSettings(
      placement: CaptionPlacement.values
          .where((value) => value.name == json['placement'])
          .firstOrNull,
      entrance:
          CaptionEntrance.values
              .where((value) => value.name == json['entrance'])
              .firstOrNull ??
          CaptionEntrance.none,
      startFraction: start < end ? start : 0,
      endFraction: start < end ? end : 1,
      preset: CaptionStylePreset.values
          .where((value) => value.name == json['preset'])
          .firstOrNull,
      sizeScale: ((json['sizeScale'] as num?)?.toDouble() ?? 1).clamp(0.7, 1.4),
      textColor:
          CaptionTextColor.values
              .where((value) => value.name == json['textColor'])
              .firstOrNull ??
          CaptionTextColor.white,
      backdrop:
          CaptionBackdrop.values
              .where((value) => value.name == json['backdrop'])
              .firstOrNull ??
          CaptionBackdrop.legacy,
    );
  }

  CaptionSettings applyPreset(CaptionStylePreset value) => copyWith(
    preset: value,
    sizeScale: switch (value) {
      CaptionStylePreset.clean => 1,
      CaptionStylePreset.softBackdrop => 1,
      CaptionStylePreset.bold => 1.15,
    },
    textColor: value == CaptionStylePreset.clean
        ? CaptionTextColor.white
        : CaptionTextColor.white,
    backdrop: switch (value) {
      CaptionStylePreset.clean => CaptionBackdrop.none,
      CaptionStylePreset.softBackdrop => CaptionBackdrop.panel,
      CaptionStylePreset.bold => CaptionBackdrop.strongPanel,
    },
  );

  CaptionSettings copyWith({
    CaptionPlacement? placement,
    CaptionEntrance? entrance,
    double? startFraction,
    double? endFraction,
    CaptionStylePreset? preset,
    double? sizeScale,
    CaptionTextColor? textColor,
    CaptionBackdrop? backdrop,
    bool clearPreset = false,
  }) => CaptionSettings(
    placement: placement ?? this.placement,
    entrance: entrance ?? this.entrance,
    startFraction: startFraction ?? this.startFraction,
    endFraction: endFraction ?? this.endFraction,
    preset: clearPreset ? null : preset ?? this.preset,
    sizeScale: sizeScale ?? this.sizeScale,
    textColor: textColor ?? this.textColor,
    backdrop: backdrop ?? this.backdrop,
  );

  CaptionSettings copyStyleFrom(CaptionSettings source) => copyWith(
    preset: source.preset,
    sizeScale: source.sizeScale,
    textColor: source.textColor,
    backdrop: source.backdrop,
    clearPreset: source.preset == null,
  );

  CaptionTiming timingFor(Duration clipDuration) {
    final durationMicros = clipDuration.inMicroseconds.toDouble();
    final startMicros = durationMicros * startFraction;
    final endMicros = durationMicros * endFraction;
    final visibleSpanMicros = endMicros - startMicros;
    return CaptionTiming(
      startMicroseconds: startMicros,
      endMicroseconds: endMicros,
      entranceMicroseconds: visibleSpanMicros < 800000
          ? visibleSpanMicros / 2
          : 400000,
    );
  }

  CaptionFrame evaluate(Duration elapsed, Duration clipDuration) {
    if (clipDuration <= Duration.zero) {
      return const CaptionFrame(
        visible: false,
        opacity: 0,
        entranceProgress: 0,
      );
    }
    final fraction = (elapsed.inMicroseconds / clipDuration.inMicroseconds)
        .clamp(0.0, 1.0);
    final visible =
        fraction >= startFraction &&
        (fraction < endFraction || (endFraction == 1 && fraction == 1));
    if (!visible) {
      return const CaptionFrame(
        visible: false,
        opacity: 0,
        entranceProgress: 0,
      );
    }
    final timing = timingFor(clipDuration);
    final sinceStart =
        clipDuration.inMicroseconds * fraction - timing.startMicroseconds;
    final progress =
        entrance == CaptionEntrance.none || timing.entranceMicroseconds <= 0
        ? 1.0
        : (sinceStart / timing.entranceMicroseconds).clamp(0.0, 1.0);
    return CaptionFrame(
      visible: true,
      opacity: entrance == CaptionEntrance.fade ? progress : 1,
      entranceProgress: progress,
    );
  }
}

class CaptionTiming {
  const CaptionTiming({
    required this.startMicroseconds,
    required this.endMicroseconds,
    required this.entranceMicroseconds,
  });

  final double startMicroseconds;
  final double endMicroseconds;
  final double entranceMicroseconds;
}

class CaptionFrame {
  const CaptionFrame({
    required this.visible,
    required this.opacity,
    required this.entranceProgress,
  });
  final bool visible;
  final double opacity;
  final double entranceProgress;
}
