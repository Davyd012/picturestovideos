import 'package:flutter/material.dart';
import 'package:picturestovideos/commons/navigation/app_route_args.dart';
import 'package:picturestovideos/commons/navigation/app_routes.dart';
import 'package:picturestovideos/features/audio_import/audio_import_screen.dart';
import 'package:picturestovideos/features/editor/audio_editor_screen.dart';
import 'package:picturestovideos/features/library/library_screen.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';
import 'package:picturestovideos/shared/widgets/app_shell_scaffold.dart';

class ScreenFactory {
  const ScreenFactory._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
      case AppRoutes.importAudio:
        return _buildRoute(
          settings: settings,
          builder: (_) => const AudioImportScreen(),
        );
      case AppRoutes.library:
        return _buildRoute(
          settings: settings,
          builder: (_) => const LibraryScreen(),
        );
      case AppRoutes.audioEditor:
        return _buildRoute(
          settings: settings,
          builder: (_) => const AudioEditorScreen(),
        );
      case AppRoutes.download:
        return _buildRoute(
          settings: settings,
          builder: (_) => const _PlannedScreen(
            args: PlannedScreenArgs(
              title: 'Export / Download',
              route: AppRoutes.download,
              referenceFile: 'DOWNLOAD_SCREEN.html',
              recommendedStartOrder: 4,
              summary:
                  'Export confirmation, file delivery, and share destinations.',
            ),
          ),
        );
      default:
        return _buildRoute(
          settings: settings,
          builder: (_) => _UnknownRouteScreen(routeName: settings.name),
        );
    }
  }

  static MaterialPageRoute<dynamic> _buildRoute({
    required RouteSettings settings,
    required WidgetBuilder builder,
  }) {
    return MaterialPageRoute<dynamic>(builder: builder, settings: settings);
  }
}

class _PlannedScreen extends StatelessWidget {
  const _PlannedScreen({required this.args});

  final PlannedScreenArgs args;

  @override
  Widget build(BuildContext context) {
    return AppShellScaffold(
      currentRoute: args.route,
      title: args.title,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card.outlined(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Route'),
                  subtitle: Text(args.route),
                ),
                ListTile(
                  title: const Text('UI Reference'),
                  subtitle: Text(args.referenceFile),
                ),
                ListTile(
                  title: const Text('Recommended Build Order'),
                  subtitle: Text('${args.recommendedStartOrder}'),
                ),
                ListTile(
                  title: const Text('Summary'),
                  subtitle: Text(args.summary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'This route is planned and documented, but the production screen is not implemented yet.',
                style: context.textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen({required this.routeName});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unknown Route')),
      body: Center(child: Text(routeName ?? 'No route name')),
    );
  }
}
