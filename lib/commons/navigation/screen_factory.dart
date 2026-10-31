import 'package:flutter/material.dart';
import 'package:picturestovideos/commons/navigation/app_routes.dart';
import 'package:picturestovideos/features/audio_import/audio_import_screen.dart';
import 'package:picturestovideos/features/editor/audio_editor_screen.dart';
import 'package:picturestovideos/features/editor/queue_screen.dart';
import 'package:picturestovideos/features/editor/image_settings_screen.dart';
import 'package:picturestovideos/features/export/export_screen.dart';
import 'package:picturestovideos/features/home/home_screen.dart';
import 'package:picturestovideos/features/library/library_screen.dart';

class ScreenFactory {
  const ScreenFactory._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return _buildRoute(
          settings: settings,
          builder: (_) => const HomeScreen(),
        );
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
      case AppRoutes.editorQueue:
        return _buildRoute(
          settings: settings,
          builder: (_) => const QueueScreen(),
        );
      case AppRoutes.imageSettings:
        final clipId = settings.arguments;
        if (clipId is! String) {
          return _buildRoute(
            settings: settings,
            builder: (_) => _UnknownRouteScreen(routeName: settings.name),
          );
        }
        return _buildRoute(
          settings: settings,
          builder: (_) => ImageSettingsScreen(clipId: clipId),
        );
      case AppRoutes.download:
        return _buildRoute(
          settings: settings,
          builder: (_) => const ExportScreen(),
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
