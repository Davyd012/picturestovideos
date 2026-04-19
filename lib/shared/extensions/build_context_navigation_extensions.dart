import 'package:flutter/widgets.dart';
import 'package:picturestovideos/commons/navigation/app_navigator.dart';

extension BuildContextNavigationExtensions on BuildContext {
  AppNavigator get appNavigator => AppNavigator.instance;
}
