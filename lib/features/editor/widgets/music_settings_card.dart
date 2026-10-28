import 'package:flutter/material.dart';
import 'package:picturestovideos/core/audio/domain/audio_mix.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';

class MusicSettingsCard extends StatelessWidget {
  const MusicSettingsCard({
    required this.mix,
    required this.sourceDuration,
    required this.onChanged,
    super.key,
  });
  final AudioMix mix;
  final Duration? sourceDuration;
  final ValueChanged<AudioMix> onChanged;

  @override
  Widget build(BuildContext context) => Card.outlined(
    child: ListTile(
      leading: const Icon(Icons.music_note),
      title: Text(context.l10n.musicSettings),
      trailing: const Icon(Icons.edit_outlined),
      onTap: () async {
        final result = await showDialog<AudioMix>(
          context: context,
          builder: (context) =>
              _MusicDialog(mix: mix, sourceDuration: sourceDuration),
        );
        if (result != null) onChanged(result);
      },
    ),
  );
}

class _MusicDialog extends StatefulWidget {
  const _MusicDialog({required this.mix, required this.sourceDuration});
  final AudioMix mix;
  final Duration? sourceDuration;
  @override
  State<_MusicDialog> createState() => _MusicDialogState();
}

class _MusicDialogState extends State<_MusicDialog> {
  late String start;
  late String end;
  late String fadeIn;
  late String fadeOut;
  bool invalid = false;
  String _format(Duration value) =>
      (value.inMilliseconds / 1000).toStringAsFixed(3);

  @override
  void initState() {
    super.initState();
    start = _format(widget.mix.start);
    end = widget.mix.end == null ? '' : _format(widget.mix.end!);
    fadeIn = _format(widget.mix.fadeIn);
    fadeOut = _format(widget.mix.fadeOut);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.musicSettings),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.musicRangeExplanation),
          _field(start, context.l10n.musicStart, (value) => start = value),
          _field(end, context.l10n.musicEnd, (value) => end = value),
          _field(fadeIn, context.l10n.musicFadeIn, (value) => fadeIn = value),
          _field(
            fadeOut,
            context.l10n.musicFadeOut,
            (value) => fadeOut = value,
          ),
          if (invalid) Text(context.l10n.musicRangeInvalid),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(onPressed: _apply, child: Text(context.l10n.apply)),
    ],
  );

  Widget _field(String value, String label, ValueChanged<String> onChanged) =>
      TextFormField(
        initialValue: value,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        onChanged: onChanged,
      );

  void _apply() {
    double? number(String value) =>
        double.tryParse(value.trim().replaceAll(',', '.'));
    final from = number(start),
        to = end.trim().isEmpty ? null : number(end),
        first = number(fadeIn),
        last = number(fadeOut);
    final limit = widget.sourceDuration?.inMilliseconds;
    final values = [from, first, last];
    if (values.any(
          (value) =>
              value == null || !value.isFinite || value < 0 || value > 86400,
        ) ||
        (end.trim().isNotEmpty && (to == null || !to.isFinite || to > 86400)) ||
        (to != null && to <= from!) ||
        (limit != null &&
            (from! * 1000 >= limit || (to != null && to * 1000 > limit)))) {
      setState(() => invalid = true);
      return;
    }
    Duration asDuration(double seconds) =>
        Duration(milliseconds: (seconds * 1000).round());
    Navigator.pop(
      context,
      AudioMix(
        start: asDuration(from!),
        end: to == null ? null : asDuration(to),
        fadeIn: asDuration(first!),
        fadeOut: asDuration(last!),
      ),
    );
  }
}
