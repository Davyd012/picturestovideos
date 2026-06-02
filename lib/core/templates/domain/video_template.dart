enum VideoTemplateAspectRatio {
  landscape('16:9', 16 / 9),
  portrait('9:16', 9 / 16);

  const VideoTemplateAspectRatio(this.label, this.value);

  final String label;
  final double value;

  static VideoTemplateAspectRatio fromJson(String? value) {
    return switch (value) {
      '9:16' || 'portrait' => VideoTemplateAspectRatio.portrait,
      _ => VideoTemplateAspectRatio.landscape,
    };
  }
}

enum VideoTemplateImageFit {
  cover,
  contain;

  static VideoTemplateImageFit fromJson(String? value) {
    return switch (value) {
      'contain' => VideoTemplateImageFit.contain,
      _ => VideoTemplateImageFit.cover,
    };
  }
}

enum VideoTemplateImageAnimation {
  slowZoomIn,
  slowZoomOut,
  softPopIn,
  quickPunchZoom,
  none;

  static VideoTemplateImageAnimation fromJson(String? value) {
    return switch (value) {
      'slow_zoom_out' => VideoTemplateImageAnimation.slowZoomOut,
      'soft_pop_in' => VideoTemplateImageAnimation.softPopIn,
      'quick_punch_zoom' => VideoTemplateImageAnimation.quickPunchZoom,
      'none' => VideoTemplateImageAnimation.none,
      _ => VideoTemplateImageAnimation.slowZoomIn,
    };
  }

  String get jsonValue {
    return switch (this) {
      VideoTemplateImageAnimation.slowZoomIn => 'slow_zoom_in',
      VideoTemplateImageAnimation.slowZoomOut => 'slow_zoom_out',
      VideoTemplateImageAnimation.softPopIn => 'soft_pop_in',
      VideoTemplateImageAnimation.quickPunchZoom => 'quick_punch_zoom',
      VideoTemplateImageAnimation.none => 'none',
    };
  }
}

enum VideoTemplateTextPlacement {
  bottomCenter,
  lowerThird,
  center,
  belowImage,
  insideTextBox;

  static VideoTemplateTextPlacement fromJson(String? value) {
    return switch (value) {
      'lower_third' => VideoTemplateTextPlacement.lowerThird,
      'center' => VideoTemplateTextPlacement.center,
      'below_image' => VideoTemplateTextPlacement.belowImage,
      'inside_text_box' => VideoTemplateTextPlacement.insideTextBox,
      _ => VideoTemplateTextPlacement.bottomCenter,
    };
  }

  String get jsonValue {
    return switch (this) {
      VideoTemplateTextPlacement.bottomCenter => 'bottom_center',
      VideoTemplateTextPlacement.lowerThird => 'lower_third',
      VideoTemplateTextPlacement.center => 'center',
      VideoTemplateTextPlacement.belowImage => 'below_image',
      VideoTemplateTextPlacement.insideTextBox => 'inside_text_box',
    };
  }
}

enum VideoTemplateOverlayStyle {
  none,
  bottomScrim,
  cinematicScrim,
  textPanel;

  static VideoTemplateOverlayStyle fromJson(String? value) {
    return switch (value) {
      'none' => VideoTemplateOverlayStyle.none,
      'cinematic_scrim' => VideoTemplateOverlayStyle.cinematicScrim,
      'text_panel' => VideoTemplateOverlayStyle.textPanel,
      _ => VideoTemplateOverlayStyle.bottomScrim,
    };
  }

  String get jsonValue {
    return switch (this) {
      VideoTemplateOverlayStyle.none => 'none',
      VideoTemplateOverlayStyle.bottomScrim => 'bottom_scrim',
      VideoTemplateOverlayStyle.cinematicScrim => 'cinematic_scrim',
      VideoTemplateOverlayStyle.textPanel => 'text_panel',
    };
  }
}

enum VideoTemplateFrameStyle {
  none,
  cleanBorder,
  polaroid;

  static VideoTemplateFrameStyle fromJson(String? value) {
    return switch (value) {
      'clean_border' => VideoTemplateFrameStyle.cleanBorder,
      'polaroid' => VideoTemplateFrameStyle.polaroid,
      _ => VideoTemplateFrameStyle.none,
    };
  }

  String get jsonValue {
    return switch (this) {
      VideoTemplateFrameStyle.none => 'none',
      VideoTemplateFrameStyle.cleanBorder => 'clean_border',
      VideoTemplateFrameStyle.polaroid => 'polaroid',
    };
  }
}

enum VideoTemplateTransition {
  fade,
  crossfade,
  slideLeft,
  hardCut;

  static VideoTemplateTransition fromJson(String? value) {
    return switch (value) {
      'crossfade' => VideoTemplateTransition.crossfade,
      'slide_left' => VideoTemplateTransition.slideLeft,
      'hard_cut' => VideoTemplateTransition.hardCut,
      _ => VideoTemplateTransition.fade,
    };
  }

  String get jsonValue {
    return switch (this) {
      VideoTemplateTransition.fade => 'fade',
      VideoTemplateTransition.crossfade => 'crossfade',
      VideoTemplateTransition.slideLeft => 'slide_left',
      VideoTemplateTransition.hardCut => 'hard_cut',
    };
  }
}

class VideoTemplate {
  const VideoTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.aspectRatio,
    required this.defaultSlideDuration,
    required this.imageFit,
    required this.imageAnimation,
    required this.textPlacement,
    required this.overlayStyle,
    required this.frameStyle,
    required this.transition,
  });

  final String id;
  final String name;
  final String description;
  final VideoTemplateAspectRatio aspectRatio;
  final Duration defaultSlideDuration;
  final VideoTemplateImageFit imageFit;
  final VideoTemplateImageAnimation imageAnimation;
  final VideoTemplateTextPlacement textPlacement;
  final VideoTemplateOverlayStyle overlayStyle;
  final VideoTemplateFrameStyle frameStyle;
  final VideoTemplateTransition transition;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'aspectRatio': aspectRatio.label,
      'defaultSlideDurationMs': defaultSlideDuration.inMilliseconds,
      'imageFit': imageFit.name,
      'imageAnimation': imageAnimation.jsonValue,
      'textPlacement': textPlacement.jsonValue,
      'overlayStyle': overlayStyle.jsonValue,
      'frameStyle': frameStyle.jsonValue,
      'transition': transition.jsonValue,
    };
  }

  factory VideoTemplate.fromJson(Map<String, Object?> json) {
    return VideoTemplate(
      id: json['id']! as String,
      name: json['name']! as String,
      description: json['description']! as String,
      aspectRatio: VideoTemplateAspectRatio.fromJson(
        json['aspectRatio'] as String?,
      ),
      defaultSlideDuration: Duration(
        milliseconds: json['defaultSlideDurationMs']! as int,
      ),
      imageFit: VideoTemplateImageFit.fromJson(json['imageFit'] as String?),
      imageAnimation: VideoTemplateImageAnimation.fromJson(
        json['imageAnimation'] as String?,
      ),
      textPlacement: VideoTemplateTextPlacement.fromJson(
        json['textPlacement'] as String?,
      ),
      overlayStyle: VideoTemplateOverlayStyle.fromJson(
        json['overlayStyle'] as String?,
      ),
      frameStyle: VideoTemplateFrameStyle.fromJson(
        json['frameStyle'] as String?,
      ),
      transition: VideoTemplateTransition.fromJson(
        json['transition'] as String?,
      ),
    );
  }

  VideoTemplate copyWith({
    String? id,
    String? name,
    String? description,
    VideoTemplateAspectRatio? aspectRatio,
    Duration? defaultSlideDuration,
    VideoTemplateImageFit? imageFit,
    VideoTemplateImageAnimation? imageAnimation,
    VideoTemplateTextPlacement? textPlacement,
    VideoTemplateOverlayStyle? overlayStyle,
    VideoTemplateFrameStyle? frameStyle,
    VideoTemplateTransition? transition,
  }) {
    return VideoTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      defaultSlideDuration: defaultSlideDuration ?? this.defaultSlideDuration,
      imageFit: imageFit ?? this.imageFit,
      imageAnimation: imageAnimation ?? this.imageAnimation,
      textPlacement: textPlacement ?? this.textPlacement,
      overlayStyle: overlayStyle ?? this.overlayStyle,
      frameStyle: frameStyle ?? this.frameStyle,
      transition: transition ?? this.transition,
    );
  }
}
