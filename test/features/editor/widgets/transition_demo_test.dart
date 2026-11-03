import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/features/editor/widgets/transition_demo.dart';

void main() {
  testWidgets('zoom demonstration uses the export transition curve', (
    tester,
  ) async {
    Widget preview(int revision) => MaterialApp(
      home: Scaffold(
        body: TransitionDemo(
          type: ClipTransitionType.zoom,
          duration: const Duration(milliseconds: 400),
          outgoingPath: '',
          incomingPath: '',
          selectionRevision: revision,
        ),
      ),
    );
    await tester.pumpWidget(preview(0));
    await tester.pumpWidget(preview(1));
    await tester.pump(const Duration(milliseconds: 100));
    final transform = tester.widget<Transform>(
      find
          .descendant(
            of: find.byType(TransitionDemo),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(transform.transform.storage[0], closeTo(2, 0.01));
    await tester.pumpAndSettle();
  });
  testWidgets('only demonstrates a transition after a selection', (
    tester,
  ) async {
    Widget preview(int revision) => MaterialApp(
      home: Scaffold(
        body: TransitionDemo(
          type: ClipTransitionType.dissolve,
          duration: const Duration(milliseconds: 300),
          outgoingPath: '',
          incomingPath: '',
          selectionRevision: revision,
        ),
      ),
    );
    await tester.pumpWidget(preview(0));
    expect(find.text('Transition preview'), findsNothing);
    await tester.pumpWidget(preview(1));
    expect(find.text('Transition preview'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });
}
