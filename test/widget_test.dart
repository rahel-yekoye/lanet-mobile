import 'package:flutter_test/flutter_test.dart';

import 'package:lanet_mobile/main.dart';

void main() {
  testWidgets('App should build and show initial screen',
      (WidgetTester tester) async {
    // Build the app without const since MyApp isn't a const widget
    await tester.pumpWidget(MyApp());

    // Verify the app starts up correctly
    expect(find.byType(MyApp), findsOneWidget);

    // Add more specific tests here based on your app's initial screen
    // For example:
    // expect(find.text('Your App Title'), findsOneWidget);
    // expect(find.byType(YourMainWidget), findsOneWidget);
  });
}
