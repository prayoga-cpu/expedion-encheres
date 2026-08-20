// The validation-devis page rendered as a blank body under a working header:
// no Flutter error, no console output, just empty space where the two price
// cards and the pay/confirm buttons should have been.
//
// The cause was a single `Expanded` wrapping almost the entire page body (851
// lines, from the price cards down to the buttons) inside a plain `Column`
// inside a `SingleChildScrollView`. A scroll view gives its child unbounded
// height, and `Expanded` cannot divide unbounded space — the textbook
// "RenderFlex children have non-zero flex, but incoming height constraints
// are unbounded" failure. In debug mode that throws loudly; nothing else in
// this app's many other `SingleChildScrollView > Column` pages hit it, because
// none of them wrap their content in `Expanded` — a plain `Column` with no
// flex children is exactly what a scrollable page needs, since there is no
// fixed remaining space to expand into in the first place.
//
// These pin the general shape, not the specific widget, so any future page
// built the same way is protected by the same test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scrollableColumnOf(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: 900.0,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const Text('Choisissez votre assurance'),
                    child,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  group('a scrollable page body', () {
    testWidgets('renders its content when it is a plain Column — the fix',
        (tester) async {
      await tester.pumpWidget(
        _scrollableColumnOf(
          Column(
            mainAxisSize: MainAxisSize.max,
            children: const [Text('ADV card'), Text('STD card')],
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('ADV card'), findsOneWidget);
      expect(find.text('STD card'), findsOneWidget);
    });

    testWidgets(
        'throws when that Column is wrapped in Expanded — the original bug',
        (tester) async {
      // A RenderFlex layout failure is reported through FlutterError.onError
      // during performLayout, not thrown into the build zone — takeException()
      // does not see it. This is the exact mechanism that made the real bug
      // silent: nothing printed to the console the app's own code could catch.
      final errors = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = errors.add;

      await tester.pumpWidget(
        _scrollableColumnOf(
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: const [Text('ADV card'), Text('STD card')],
            ),
          ),
        ),
      );
      await tester.pump();
      FlutterError.onError = previous;

      // This is the exact failure mode the blank page had: RenderFlex cannot
      // resolve a flex child against the infinite height a scroll view hands
      // its content, and the two Text widgets never reach the screen.
      expect(errors, isNotEmpty);
      expect(
        errors.map((e) => e.exceptionAsString()).join('\n'),
        contains('RenderFlex children have non-zero flex'),
      );
    });
  });
}
