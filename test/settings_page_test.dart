import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:s3gui/pages/settings.dart';

void main() {
  group('SettingsPage', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    Widget buildApp() {
      return MaterialApp(
        home: SettingsPage(onToggleTheme: () {}),
      );
    }

    testWidgets('renders required form fields', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Endpoint'), findsOneWidget);
      expect(find.text('Access Key'), findsOneWidget);
      expect(find.text('Secret Key'), findsOneWidget);
    });

    testWidgets('renders optional fields', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Scroll down to find optional fields
      await tester.scrollUntilVisible(
          find.text('Default Bucket'), 100,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Default Bucket'), findsOneWidget);
      expect(find.text('Region'), findsOneWidget);
    });

    testWidgets('shows validation errors on empty submit', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Scroll to and tap save button
      await tester.scrollUntilVisible(
          find.text('Save & Connect'), 100,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Save & Connect'));
      await tester.pumpAndSettle();

      // Validation errors should be visible (form scrolls to first error)
      expect(find.text('Endpoint is required'), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
