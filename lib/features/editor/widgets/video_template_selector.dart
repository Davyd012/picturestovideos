import 'package:flutter/material.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/preview/domain/render_capabilities.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class VideoTemplateSelector extends StatelessWidget {
  const VideoTemplateSelector({
    required this.selectedTemplate,
    required this.onTemplateSelected,
    this.renderCapabilities,
    this.gateRenderCapabilities = false,
    this.capabilityProbeFailed = false,
    this.clipCount = 1,
    super.key,
  });
  final VideoTemplate selectedTemplate;
  final ValueChanged<VideoTemplate> onTemplateSelected;
  final RenderCapabilities? renderCapabilities;
  final bool gateRenderCapabilities;
  final bool capabilityProbeFailed;
  final int clipCount;

  @override
  Widget build(BuildContext context) {
    final capabilities = renderCapabilities;
    final capabilityNotice = !gateRenderCapabilities
        ? null
        : capabilities == null
        ? capabilityProbeFailed
              ? context.l10n.exportCapabilityProbeFailed
              : context.l10n.exportCapabilityChecking
        : !capabilities.platformSupported
        ? context.l10n.exportUnsupportedPlatform
        : !capabilities.ffmpegAvailable
        ? context.l10n.exportMissingFfmpeg
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.visualStyle, style: context.textTheme.titleMedium),
        Text(
          context.l10n.styleOverridesPreserved,
          style: context.textTheme.bodyMedium,
        ),
        if (capabilityNotice != null)
          Text(capabilityNotice, style: context.textTheme.bodySmall),
        if (!VideoTemplates.featured.any(
          (style) => style.id == selectedTemplate.id,
        ))
          Text(context.l10n.legacyStyle, style: context.textTheme.bodyMedium),
        for (final style in VideoTemplates.featured) ...[
          Builder(
            builder: (context) {
              final supported =
                  !gateRenderCapabilities ||
                  (capabilityNotice == null &&
                      capabilities!.supportsTemplate(
                        style,
                        clipCount: clipCount,
                      ));
              return Semantics(
                button: true,
                enabled: supported,
                selected: selectedTemplate.id == style.id,
                child: Card.outlined(
                  child: InkWell(
                    onTap: supported ? () => onTemplateSelected(style) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          ExcludeSemantics(child: _StylePreview(style: style)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _styleName(context, style),
                                  style: context.textTheme.titleMedium,
                                ),
                                Text(
                                  _styleDescription(context, style),
                                  style: context.textTheme.bodyMedium,
                                ),
                                if (!supported && capabilityNotice == null)
                                  Text(
                                    context.l10n.styleUnavailable,
                                    style: context.textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                          if (selectedTemplate.id == style.id)
                            const Icon(Icons.check_circle),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

String _styleName(BuildContext context, VideoTemplate style) =>
    switch (style.id) {
      'calm_memories' => context.l10n.styleCalm,
      'storybook' => context.l10n.styleStorybook,
      'celebration' => context.l10n.styleCelebration,
      _ => context.l10n.legacyStyle,
    };

String _styleDescription(BuildContext context, VideoTemplate style) =>
    switch (style.id) {
      'calm_memories' => context.l10n.styleCalmDescription,
      'storybook' => context.l10n.styleStorybookDescription,
      'celebration' => context.l10n.styleCelebrationDescription,
      _ => '',
    };

class _StylePreview extends StatefulWidget {
  const _StylePreview({required this.style});
  final VideoTemplate style;
  @override
  State<_StylePreview> createState() => _StylePreviewState();
}

class _StylePreviewState extends State<_StylePreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.stop();
      controller.value = 0.5;
    } else if (!_started) {
      _started = true;
      controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 80,
    child: ClipRect(
      child: ColoredBox(
        color: context.colors.surfaceContainerHighest,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) => Transform.scale(
            scale: ClipMotion(
              preset: ClipMotionPreset.fromTemplate(
                widget.style.imageAnimation,
              ),
              intensity: widget.style.moreMovementByDefault
                  ? ClipMotionIntensity.moreMovement
                  : ClipMotionIntensity.subtle,
            ).zoomAt(controller.value),
            child: child,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.style.id == 'celebration'
                    ? Icons.celebration_outlined
                    : widget.style.id == 'storybook'
                    ? Icons.auto_stories_outlined
                    : Icons.photo_outlined,
                color: context.colors.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 32,
                child: Divider(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
