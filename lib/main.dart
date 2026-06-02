import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:picturestovideos/app.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  registerGlobalLoggingHandlers();
  runApp(const ProviderScope(child: App()));
}
