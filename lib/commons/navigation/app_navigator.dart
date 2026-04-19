import 'package:flutter/material.dart';
import 'package:picturestovideos/commons/navigation/app_routes.dart';

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

  Future<T?> goToDownload<T extends Object?>({bool replace = false}) {
    return replace
        ? replaceNamed<T, Object?>(AppRoutes.download)
        : pushNamed<T>(AppRoutes.download);
  }
}
