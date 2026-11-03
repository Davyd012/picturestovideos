import 'package:flutter/material.dart';
import 'package:picturestovideos/commons/navigation/app_route_args.dart';
import 'package:picturestovideos/commons/navigation/app_routes.dart';
import 'package:picturestovideos/features/editor/image_settings_screen.dart';

class AppNavigator {
  AppNavigator._();

  static final instance = AppNavigator._();

  final navigatorKey = GlobalKey<NavigatorState>();

  Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  Future<T?> replaceNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushReplacementNamed<T, TO>(
      routeName,
      result: result,
      arguments: arguments,
    );
  }

  Future<bool> maybePop<T extends Object?>([T? result]) {
    return navigatorKey.currentState!.maybePop<T>(result);
  }

  Future<T?> goToHome<T extends Object?>({bool replace = false}) {
    return replace
        ? replaceNamed<T, Object?>(AppRoutes.home)
        : pushNamed<T>(AppRoutes.home);
  }

  Future<T?> goToImportAudio<T extends Object?>({bool replace = false}) {
    return replace
        ? replaceNamed<T, Object?>(AppRoutes.importAudio)
        : pushNamed<T>(AppRoutes.importAudio);
  }

  Future<T?> goToLibrary<T extends Object?>({bool replace = false}) {
    return replace
        ? replaceNamed<T, Object?>(AppRoutes.library)
        : pushNamed<T>(AppRoutes.library);
  }

  Future<T?> goToAudioEditor<T extends Object?>({bool replace = false}) {
    return replace
        ? replaceNamed<T, Object?>(AppRoutes.audioEditor)
        : pushNamed<T>(AppRoutes.audioEditor);
  }

  Future<T?> goToEditorQueue<T extends Object?>() =>
      pushNamed<T>(AppRoutes.editorQueue);
  Future<T?> goToImageSettings<T extends Object?>(
    String clipId, {
    ImageSettingsSection section = ImageSettingsSection.framing,
  }) => _showImageSettings<T>(
    ImageSettingsRouteArgs.forClip(clipId, section: section),
  );

  Future<T?> _showImageSettings<T extends Object?>(
    ImageSettingsRouteArgs args,
  ) {
    final context = navigatorKey.currentContext!;
    if (MediaQuery.sizeOf(context).width < 600) {
      return pushNamed<T>(AppRoutes.imageSettings, arguments: args);
    }
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, _) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 900),
          child: ImageSettingsScreen(args: args),
        ),
      ),
      transitionBuilder: (context, animation, _, child) =>
          MediaQuery.disableAnimationsOf(context)
          ? child
          : FadeTransition(opacity: animation, child: child),
    );
  }

  Future<T?> goToQueuedImageSettings<T extends Object?>(String mediaId) =>
      _showImageSettings<T>(ImageSettingsRouteArgs.forQueuedMedia(mediaId));

  Future<T?> goToDownload<T extends Object?>({bool replace = false}) {
    return replace
        ? replaceNamed<T, Object?>(AppRoutes.download)
        : pushNamed<T>(AppRoutes.download);
  }
}
