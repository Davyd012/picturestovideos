import 'package:flutter/material.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class VideoTemplateSelector extends StatelessWidget {
  const VideoTemplateSelector({
    super.key,
    required this.selectedTemplate,
    required this.onTemplateSelected,
  });

  final VideoTemplate selectedTemplate;
  final ValueChanged<VideoTemplate> onTemplateSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Template', style: context.textTheme.titleMedium),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: VideoTemplates.byId(selectedTemplate.id).id,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.auto_awesome_mosaic_outlined),
            labelText: 'Video preset',
          ),
          items: [
            for (final template in VideoTemplates.all)
              DropdownMenuItem(value: template.id, child: Text(template.name)),
          ],
          onChanged: (id) {
            if (id == null) {
              return;
            }
            onTemplateSelected(VideoTemplates.byId(id));
          },
        ),
        const SizedBox(height: 12),
        Text(selectedTemplate.description, style: context.textTheme.bodyMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text(selectedTemplate.aspectRatio.label)),
            Chip(label: Text(_durationLabel(selectedTemplate))),
            Chip(label: Text(selectedTemplate.transition.jsonValue)),
          ],
        ),
      ],
    );
  }

  String _durationLabel(VideoTemplate template) {
    final milliseconds = template.defaultSlideDuration.inMilliseconds;
    final seconds = milliseconds / 1000;
    return '${seconds.toStringAsFixed(seconds >= 2 ? 0 : 1)}s clips';
  }
}
