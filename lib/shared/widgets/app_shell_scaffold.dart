import 'package:flutter/material.dart';
import 'package:picturestovideos/commons/navigation/app_routes.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_navigation_extensions.dart';

class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({
    required this.currentRoute,
    required this.title,
    required this.body,
    super.key,
    this.actions = const [],
    this.leading,
  });

  final String currentRoute;
  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? leading;

  List<_ShellDestination> _destinations(BuildContext context) => [
    _ShellDestination(
      route: AppRoutes.home,
      label: context.l10n.homeTitle,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _ShellDestination(
      route: AppRoutes.importAudio,
      label: context.l10n.navImport,
      icon: Icons.audio_file_outlined,
      selectedIcon: Icons.audio_file,
    ),
    _ShellDestination(
      route: AppRoutes.library,
      label: context.l10n.navLibrary,
      icon: Icons.video_library_outlined,
      selectedIcon: Icons.video_library,
    ),
    _ShellDestination(
      route: AppRoutes.audioEditor,
      label: context.l10n.navEditor,
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune,
    ),
    _ShellDestination(
      route: AppRoutes.download,
      label: context.l10n.navExport,
      icon: Icons.download_outlined,
      selectedIcon: Icons.download,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations(context);
    final selectedIndex = _selectedIndexFor(currentRoute, destinations);

    return LayoutBuilder(
      builder: (context, constraints) {
        final showRail = constraints.maxWidth >= 960;

        return Scaffold(
          appBar: AppBar(
            leading: leading,
            title: Text(title),
            actions: actions,
          ),
          body: SafeArea(
            child: showRail
                ? Row(
                    children: [
                      NavigationRail(
                        selectedIndex: selectedIndex,
                        labelType: NavigationRailLabelType.all,
                        destinations: [
                          for (final destination in destinations)
                            NavigationRailDestination(
                              icon: Icon(destination.icon),
                              selectedIcon: Icon(destination.selectedIcon),
                              label: Text(destination.label),
                            ),
                        ],
                        onDestinationSelected: (index) {
                          _handleDestinationSelected(
                            context,
                            destinations[index].route,
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
                    for (final destination in destinations)
                      NavigationDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: destination.label,
                      ),
                  ],
                  onDestinationSelected: (index) {
                    _handleDestinationSelected(
                      context,
                      destinations[index].route,
                    );
                  },
                ),
        );
      },
    );
  }

  int _selectedIndexFor(String route, List<_ShellDestination> destinations) {
    return destinations.indexWhere((destination) => destination.route == route);
  }

  void _handleDestinationSelected(BuildContext context, String route) {
    if (route == currentRoute) {
      return;
    }

    switch (route) {
      case AppRoutes.home:
        context.appNavigator.goToHome(replace: true);
        return;
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
