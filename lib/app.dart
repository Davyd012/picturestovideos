import 'package:flutter/material.dart';
import 'package:picturestovideos/commons/navigation/app_navigator.dart';
import 'package:picturestovideos/commons/navigation/app_routes.dart';
import 'package:picturestovideos/commons/navigation/screen_factory.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/core/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.instance.navigatorKey,
      navigatorObservers: [appTalkerRouteObserver],
      initialRoute: AppRoutes.importAudio,
      onGenerateRoute: ScreenFactory.onGenerateRoute,
      theme: AppTheme.dark(),
    );
  }
}
