import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic widget smoke test', (WidgetTester tester) async {
    // Keep the default widget test isolated from Firebase/plugin setup.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Doctor App'),
        ),
      ),
    );

    // Verify the widget tree is rendered.
    await tester.pump();
    expect(find.text('Doctor App'), findsOneWidget);
  });
}
