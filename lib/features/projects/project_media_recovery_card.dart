import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/features/projects/project_media_recovery.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';

class ProjectMediaRecoveryCard extends ConsumerWidget {
  const ProjectMediaRecoveryCard({required this.project, super.key});
  final ProjectTimeline project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missing =
        ref.watch(missingProjectMediaProvider(project)).asData?.value ??
        const <MissingProjectMedia>[];
    if (missing.isEmpty) return const SizedBox.shrink();
    return Card.outlined(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.error_outline),
            title: Text(context.l10n.missingProjectFiles),
          ),
          for (final item in missing)
            ListTile(
              title: Text(
                item.isAudio
                    ? context.l10n.missingAudio
                    : context.l10n.missingImage,
              ),
              subtitle: Text(
                item.path,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: TextButton(
                onPressed: () => _relink(context, ref, item),
                child: Text(context.l10n.relink),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _relink(
    BuildContext context,
    WidgetRef ref,
    MissingProjectMedia item,
  ) async {
    try {
      final changed = await ref
          .read(projectMediaRecoveryProvider)
          .relink(project, item);
      if (changed && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.relinkSaveReminder)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.relinkFailed)));
      }
    }
  }
}
