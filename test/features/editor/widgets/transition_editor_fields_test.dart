import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/features/editor/widgets/transition_editor_fields.dart';

void main() {
  testWidgets('shows inherited transition and duration and reports edits', (
    tester,
  ) async {
    ClipTransitionType? selected;
    Duration? duration;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransitionEditorFields(
            type: null,
            inheritedType: ClipTransitionType.dissolve,
            duration: const Duration(milliseconds: 500),
            isClamped: false,
            onTypeChanged: (value) => selected = value,
            onDurationChanged: (value) => duration = value,
          ),
        ),
      ),
    );
    expect(find.textContaining('Dissolve'), findsOneWidget);
    expect(find.text('0.5 s'), findsOneWidget);
    final dropdown = tester
        .widget<DropdownButtonFormField<ClipTransitionType?>>(
          find.byType(DropdownButtonFormField<ClipTransitionType?>),
        );
    dropdown.onChanged!(ClipTransitionType.slide);
    expect(selected, ClipTransitionType.slide);
    await tester.tap(find.byType(DropdownButtonFormField<ClipTransitionType?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zoom').last);
    await tester.pumpAndSettle();
    expect(selected, ClipTransitionType.zoom);
    tester.widget<Slider>(find.byType(Slider)).onChanged!(800);
    expect(duration, const Duration(milliseconds: 800));
  });
}
