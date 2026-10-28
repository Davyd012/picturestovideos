import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/features/editor/widgets/caption_settings_fields.dart';

void main() {
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
              overflow: true,
              shortReadingTime: true,
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('exceeds the safe area'), findsOneWidget);
    expect(find.textContaining('difficult to read'), findsOneWidget);
    await tester.tap(find.text('Style default'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Top').last);
    await tester.pumpAndSettle();
    expect(selected?.placement, CaptionPlacement.top);
    final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
    slider.onChanged!(const RangeValues(0.25, 0.75));
    expect(selected?.startFraction, 0.25);
    expect(selected?.endFraction, 0.75);
  });
}
