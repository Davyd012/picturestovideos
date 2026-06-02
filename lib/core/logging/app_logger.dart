import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

final appTalker = TalkerFlutter.init();
final appTalkerRouteObserver = TalkerRouteObserver(appTalker);

final appLoggerProvider = Provider<AppLogger>((ref) => AppLogger(appTalker));

class AppLogger {
  const AppLogger(this._talker);

  final Talker _talker;

  void debug(String tag, String message) {
    _talker.debug('[$tag] $message');
  }

  void info(String tag, String message) {
    _talker.info('[$tag] $message');
  }

  void warning(String tag, String message) {
    _talker.warning('[$tag] $message');
  }

  void error(
    String tag,
    Object error,
    StackTrace stackTrace, {
    String? message,
  }) {
    _talker.handle(
      error,
      stackTrace,
      '[$tag] ${message ?? 'Unexpected error'}',
    );
  }
}

void registerGlobalLoggingHandlers() {
  FlutterError.onError = (details) {
    appTalker.handle(
      details.exception,
      details.stack ?? StackTrace.current,
      '[FlutterError] Unhandled framework error',
    );
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    appTalker.handle(
      error,
      stackTrace,
      '[PlatformDispatcher] Unhandled platform error',
    );
    return true;
  };

  appTalker.info('[App] Logging initialized');
  if (kDebugMode) {
    appTalker.debug('[App] Debug mode enabled');
  }
}
