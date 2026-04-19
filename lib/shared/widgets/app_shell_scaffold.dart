import 'package:flutter/material.dart';
import 'package:picturestovideos/commons/navigation/app_routes.dart';
import 'package:picturestovideos/shared/extensions/build_context_navigation_extensions.dart';

class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({
    required this.currentRoute,
    required this.title,
    required this.body,
    super.key,
    this.actions = const [],
  });

  final String currentRoute;
  final String title;
  final Widget body;
  final List<Widget> actions;

  static const _destinations = <_ShellDestination>[
    _ShellDestination(
      route: AppRoutes.importAudio,
      label: 'Import',
      icon: Icons.audio_file_outlined,
      selectedIcon: Icons.audio_file,
    ),
    _ShellDestination(
      route: AppRoutes.library,
      label: 'Library',
      icon: Icons.video_library_outlined,
      selectedIcon: Icons.video_library,
    ),
    _ShellDestination(
      route: AppRoutes.audioEditor,
      label: 'Editor',
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune,
    ),
    _ShellDestination(
      route: AppRoutes.download,
      label: 'Export',
      icon: Icons.download_outlined,
      selectedIcon: Icons.download,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndexFor(currentRoute);

    return LayoutBuilder(
      builder: (context, constraints) {
        final showRail = constraints.maxWidth >= 960;

        return Scaffold(
          appBar: AppBar(title: Text(title), actions: actions),
          body: SafeArea(
            child: showRail
                ? Row(
                    children: [
                      NavigationRail(
                        selectedIndex: selectedIndex,
                        labelType: NavigationRailLabelType.all,
                        destinations: [
                          for (final destination in _destinations)
                            NavigationRailDestination(
                              icon: Icon(destination.icon),
                              selectedIcon: Icon(destination.selectedIcon),
                              label: Text(destination.label),
                            ),
                        ],
                        onDestinationSelected: (index) {
                          _handleDestinationSelected(
                            context,
                            _destinations[index].route,
                          );
                        },
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: body),
                    ],
                  )
                : body,
          ),
          bottomNavigationBar: showRail
              ? null
              : NavigationBar(
                  selectedIndex: selectedIndex,
                  destinations: [
                    for (final destination in _destinations)
                      NavigationDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: destination.label,
                      ),
                  ],
                  onDestinationSelected: (index) {
                    _handleDestinationSelected(
                      context,
                      _destinations[index].route,
                    );
                  },
                ),
        );
      },
    );
  }

  int _selectedIndexFor(String route) {
    return _destinations.indexWhere(
      (destination) => destination.route == route,
    );
  }

  void _handleDestinationSelected(BuildContext context, String route) {
    if (route == currentRoute) {
      return;
    }

    switch (route) {
      case AppRoutes.importAudio:
        context.appNavigator.goToImportAudio(replace: true);
        return;
      case AppRoutes.library:
        context.appNavigator.goToLibrary(replace: true);
        return;
      case AppRoutes.audioEditor:
        context.appNavigator.goToAudioEditor(replace: true);
        return;
      case AppRoutes.download:
        context.appNavigator.goToDownload(replace: true);
        return;
    }
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
