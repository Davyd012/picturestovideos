import 'package:flutter/material.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/preview/domain/transition_visual.dart';
import 'package:picturestovideos/features/editor/widgets/media_thumbnail.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';

class TransitionDemo extends StatefulWidget {
  const TransitionDemo({
    required this.type,
    required this.duration,
    required this.outgoingPath,
    required this.incomingPath,
    required this.selectionRevision,
    super.key,
  });
  final ClipTransitionType type;
  final Duration duration;
  final String outgoingPath;
  final String incomingPath;
  final int selectionRevision;

  @override
  State<TransitionDemo> createState() => _TransitionDemoState();
}

class _TransitionDemoState extends State<TransitionDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(vsync: this);
  bool shown = false;

  @override
  void didUpdateWidget(TransitionDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectionRevision != widget.selectionRevision) {
      shown = true;
      controller.duration =
          widget.type == ClipTransitionType.cut ||
              MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : widget.duration;
      controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!shown) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(context.l10n.transitionDemo),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRect(
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final value = controller.value;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      FractionalTranslation(
                        translation: Offset(
                          widget.type == ClipTransitionType.slide ? -value : 0,
                          0,
                        ),
                        child: Transform.scale(
                          scale: widget.type == ClipTransitionType.zoom
                              ? TransitionVisual.zoomOutgoingScale(value)
                              : 1,
                          child: MediaThumbnail(
                            path: widget.outgoingPath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (widget.type == ClipTransitionType.slide)
                        FractionalTranslation(
                          translation: Offset(1 - value, 0),
                          child: MediaThumbnail(
                            path: widget.incomingPath,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Opacity(
                          opacity: widget.type == ClipTransitionType.cut
                              ? 1
                              : widget.type == ClipTransitionType.zoom
                              ? TransitionVisual.zoomIncomingOpacity(value)
                              : value,
                          child: MediaThumbnail(
                            path: widget.incomingPath,
                            fit: BoxFit.cover,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
