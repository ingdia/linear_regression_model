import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:er_wait_time_app/main.dart';

void main() {
  Future<void> useTallSurface(WidgetTester tester) async {
    final originalSize = tester.view.physicalSize;
    final originalRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalRatio;
    });
  }

  testWidgets('Prediction page renders all required elements', (WidgetTester tester) async {
    await useTallSurface(tester);
    await tester.pumpWidget(const ErApp());
    await tester.pump(const Duration(milliseconds: 100));

    // 6 dropdown choice fields + 4 numeric text fields = 10 inputs (one per model feature).
    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(6));
    expect(find.byType(TextField), findsNWidgets(4));

    // Predict button.
    expect(find.widgetWithText(ElevatedButton, 'Predict wait time'), findsOneWidget);

    // Display area with its initial placeholder text.
    expect(find.text('Your prediction will appear here.'), findsOneWidget);
  });

  testWidgets('Shows validation message when fields are empty', (WidgetTester tester) async {
    await useTallSurface(tester);
    await tester.pumpWidget(const ErApp());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Predict wait time'));
    await tester.pump();

    expect(find.textContaining('Choose a value for'), findsOneWidget);
  });
}
