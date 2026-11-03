import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/features/editor/widgets/clip_scope_selector.dart';

void main() {
  testWidgets('both scopes remain visible on a narrow screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(32),
              child: ClipScopeSelector(
                all: false,
                clipLabel: 'This transition',
                allLabel: 'All transitions',
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('This transition').hitTestable(), findsOneWidget);
    expect(find.text('All transitions').hitTestable(), findsOneWidget);
  });
}
