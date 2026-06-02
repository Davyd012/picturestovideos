import 'package:picturestovideos/core/templates/domain/video_template.dart';

abstract final class VideoTemplates {
  static const cleanMemories = VideoTemplate(
    id: 'clean_memories',
    name: 'Clean Memories',
    description: 'Fullscreen image, soft zoom, lower caption, fade pacing.',
    aspectRatio: VideoTemplateAspectRatio.portrait,
    defaultSlideDuration: Duration(seconds: 3),
    imageFit: VideoTemplateImageFit.cover,
    imageAnimation: VideoTemplateImageAnimation.slowZoomIn,
    textPlacement: VideoTemplateTextPlacement.bottomCenter,
    overlayStyle: VideoTemplateOverlayStyle.bottomScrim,
    frameStyle: VideoTemplateFrameStyle.none,
    transition: VideoTemplateTransition.fade,
  );

  static const polaroidCollage = VideoTemplate(
    id: 'polaroid_collage',
    name: 'Polaroid Collage',
    description: 'Contained photo, white frame, date-style caption.',
    aspectRatio: VideoTemplateAspectRatio.portrait,
    defaultSlideDuration: Duration(milliseconds: 3200),
    imageFit: VideoTemplateImageFit.contain,
    imageAnimation: VideoTemplateImageAnimation.softPopIn,
    textPlacement: VideoTemplateTextPlacement.belowImage,
    overlayStyle: VideoTemplateOverlayStyle.none,
    frameStyle: VideoTemplateFrameStyle.polaroid,
    transition: VideoTemplateTransition.slideLeft,
  );

  static const cinematicDark = VideoTemplate(
    id: 'cinematic_dark',
    name: 'Cinematic Dark',
    description: 'Slow zoom, deep lower scrim, bold story title.',
    aspectRatio: VideoTemplateAspectRatio.portrait,
    defaultSlideDuration: Duration(milliseconds: 3500),
    imageFit: VideoTemplateImageFit.cover,
    imageAnimation: VideoTemplateImageAnimation.slowZoomOut,
    textPlacement: VideoTemplateTextPlacement.lowerThird,
    overlayStyle: VideoTemplateOverlayStyle.cinematicScrim,
    frameStyle: VideoTemplateFrameStyle.none,
    transition: VideoTemplateTransition.crossfade,
  );

  static const splitScreenStory = VideoTemplate(
    id: 'split_screen_story',
    name: 'Split Screen Story',
    description: 'Image area with a calm text panel for explainers.',
    aspectRatio: VideoTemplateAspectRatio.portrait,
    defaultSlideDuration: Duration(seconds: 4),
    imageFit: VideoTemplateImageFit.cover,
    imageAnimation: VideoTemplateImageAnimation.none,
    textPlacement: VideoTemplateTextPlacement.insideTextBox,
    overlayStyle: VideoTemplateOverlayStyle.textPanel,
    frameStyle: VideoTemplateFrameStyle.cleanBorder,
    transition: VideoTemplateTransition.fade,
  );

  static const fastSocialReel = VideoTemplate(
    id: 'fast_social_reel',
    name: 'Fast Social Reel',
    description: 'Short cuts, center caption, punchy beat-first pacing.',
    aspectRatio: VideoTemplateAspectRatio.portrait,
    defaultSlideDuration: Duration(milliseconds: 1200),
    imageFit: VideoTemplateImageFit.cover,
    imageAnimation: VideoTemplateImageAnimation.quickPunchZoom,
    textPlacement: VideoTemplateTextPlacement.center,
    overlayStyle: VideoTemplateOverlayStyle.cinematicScrim,
    frameStyle: VideoTemplateFrameStyle.none,
    transition: VideoTemplateTransition.hardCut,
  );

  static const all = [
    cleanMemories,
    polaroidCollage,
    cinematicDark,
    splitScreenStory,
    fastSocialReel,
  ];

  static VideoTemplate byId(String? id) {
    for (final template in all) {
      if (template.id == id) {
        return template;
      }
    }
    return cleanMemories;
  }
}
