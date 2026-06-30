import 'package:flutter/material.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class ImportEmptyState extends StatelessWidget {
  const ImportEmptyState({
    required this.onChooseFile,
    required this.onSelectSongOnly,
    required this.onImportFromPath,
    required this.onSelectSongOnlyFromPath,
    super.key,
  });

  final VoidCallback onChooseFile;
  final VoidCallback onSelectSongOnly;
  final VoidCallback onImportFromPath;
  final VoidCallback onSelectSongOnlyFromPath;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandHeader(),
                    const SizedBox(height: 32),
                    _UploadCard(
                      onChooseFile: onChooseFile,
                      onSelectSongOnly: onSelectSongOnly,
                      onImportFromPath: onImportFromPath,
                      onSelectSongOnlyFromPath: onSelectSongOnlyFromPath,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset('lib/assets/icon.png', width: 112, height: 112),
        const SizedBox(height: 24),
        Text(
          'Pictures to Videos',
          style: context.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Turn rhythm and still images into motion.',
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.onChooseFile,
    required this.onSelectSongOnly,
    required this.onImportFromPath,
    required this.onSelectSongOnlyFromPath,
  });

  final VoidCallback onChooseFile;
  final VoidCallback onSelectSongOnly;
  final VoidCallback onImportFromPath;
  final VoidCallback onSelectSongOnlyFromPath;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: context.colors.outline),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: context.colors.primary,
            ),
            const SizedBox(height: 16),
            Text('Drop a WAV file here', style: context.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Analyze a WAV file, or select any song and add markers yourself.',
              style: context.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: onChooseFile,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Analyze WAV'),
                ),
                FilledButton.tonalIcon(
                  onPressed: onSelectSongOnly,
                  icon: const Icon(Icons.library_music_outlined),
                  label: const Text('Select song only'),
                ),
                OutlinedButton.icon(
                  onPressed: onImportFromPath,
                  icon: const Icon(Icons.terminal),
                  label: const Text('WAV from path'),
                ),
                OutlinedButton.icon(
                  onPressed: onSelectSongOnlyFromPath,
                  icon: const Icon(Icons.audio_file_outlined),
                  label: const Text('Song from path'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 8), paint);
        distance += 16;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
