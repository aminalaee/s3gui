import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:s3gui/pages/settings.dart';

void main() {
  group('SettingsPage', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    testWidgets('renders all form fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsPage()),
      );
      // Wait for async credential loading
      await tester.pumpAndSettle();

      expect(find.text('Endpoint URL'), findsOneWidget);
      expect(find.text('Acess Key'), findsOneWidget);
      expect(find.text('Secret Key'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows validation errors on empty submit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsPage()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter Endpoint URL'), findsOneWidget);
      expect(find.text('Please enter Access Key'), findsOneWidget);
      expect(find.text('Please enter Secret Key'), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsPage()),
      );
      // Before pumpAndSettle — should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
