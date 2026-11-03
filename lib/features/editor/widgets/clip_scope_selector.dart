import 'package:flutter/material.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class ClipScopeSelector extends StatelessWidget {
  const ClipScopeSelector({
    required this.all,
    required this.onChanged,
    this.clipLabel,
    this.allLabel,
    this.enabled = true,
    super.key,
  });
  final bool all;
  final ValueChanged<bool> onChanged;
  final String? clipLabel;
  final String? allLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      Text(context.l10n.editorScope, style: context.textTheme.labelLarge),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: Text(clipLabel ?? context.l10n.editorScopeClip),
            selected: !all,
            onSelected: enabled ? (_) => onChanged(false) : null,
          ),
          ChoiceChip(
            label: Text(allLabel ?? context.l10n.editorScopeAll),
            selected: all,
            onSelected: enabled ? (_) => onChanged(true) : null,
          ),
        ],
      ),
    ],
  );
}
