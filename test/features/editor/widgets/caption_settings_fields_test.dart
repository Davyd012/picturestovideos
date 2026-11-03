import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/features/editor/widgets/caption_settings_fields.dart';

void main() {
  testWidgets('caption placement can return to the project default', (
    tester,
  ) async {
    CaptionSettings? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CaptionSettingsFields(
            settings: const CaptionSettings(placement: CaptionPlacement.top),
            inheritedPlacement: CaptionPlacement.bottom,
            section: CaptionEditorSection.position,
            overflow: false,
            shortReadingTime: false,
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(DropdownButtonFormField<CaptionPlacement?>));
    await tester.pumpAndSettle();
    expect(find.text('Style default: Bottom'), findsOneWidget);
    await tester.tap(find.text('Style default: Bottom'));
    await tester.pumpAndSettle();
    expect(selected?.placement, isNull);
  });
  testWidgets('exposes caption placement, entrance, timing and warnings', (
    tester,
  ) async {
    CaptionSettings? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CaptionSettingsFields(
              settings: const CaptionSettings(),
              section: CaptionEditorSection.position,
              overflow: true,
              shortReadingTime: true,
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      ),
    );
    final placementField = tester
        .widget<DropdownButtonFormField<CaptionPlacement?>>(
          find.byType(DropdownButtonFormField<CaptionPlacement?>),
        );
    expect(placementField.onChanged, isNotNull);
    placementField.onChanged!(CaptionPlacement.top);
    expect(selected?.placement, CaptionPlacement.top);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CaptionSettingsFields(
              settings: const CaptionSettings(),
              section: CaptionEditorSection.timing,
              overflow: true,
              shortReadingTime: true,
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('exceeds the safe area'), findsOneWidget);
    expect(find.textContaining('difficult to read'), findsOneWidget);
    final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
    slider.onChanged!(const RangeValues(0.25, 0.75));
    expect(selected?.startFraction, 0.25);
    expect(selected?.endFraction, 0.75);
  });
}
