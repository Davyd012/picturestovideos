import 'package:flutter/material.dart';
import 'package:picturestovideos/features/editor/editor_tab_state.dart';

class EditorSectionTabBar extends StatelessWidget {
  const EditorSectionTabBar({
    required this.selectedTab,
    required this.onTabSelected,
    super.key,
  });

  final EditorTab selectedTab;
  final ValueChanged<EditorTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('editor-section-tab-bar'),
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<EditorTab>(
        showSelectedIcon: false,
        selected: {selectedTab},
        onSelectionChanged: (tabs) => onTabSelected(tabs.single),
        segments: [
          for (final tab in EditorTab.values)
            ButtonSegment(value: tab, label: Text(tab.label)),
        ],
      ),
    );
  }
}
