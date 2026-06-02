import 'package:flutter/material.dart';
import 'package:picturestovideos/commons/navigation/app_navigator.dart';
import 'package:picturestovideos/commons/navigation/app_routes.dart';
import 'package:picturestovideos/commons/navigation/screen_factory.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.instance.navigatorKey,
      navigatorObservers: [
        appTalkerRouteObserver,
      ],
      initialRoute: AppRoutes.importAudio,
      onGenerateRoute: ScreenFactory.onGenerateRoute,
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: baseTheme.colorScheme.surface,
      ),
    );
  }
}
