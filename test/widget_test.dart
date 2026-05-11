import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:better_brushing/app.dart';
import 'package:better_brushing/controllers/app_settings_controller.dart';

void main() {
  testWidgets('shows character selection and starts the flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      BrushingApp(
        availableCameras: const [],
        settingsController: AppSettingsController(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose your character'), findsOneWidget);
    expect(find.text('Fox'), findsOneWidget);
    expect(find.text('Gator'), findsOneWidget);

    await tester.tap(find.text('Fox'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('2:00'), findsOneWidget);
    expect(find.text('Top left'), findsOneWidget);
  });

  testWidgets('adds and selects a kid profile', (WidgetTester tester) async {
    await tester.pumpWidget(
      BrushingApp(
        availableCameras: const [],
        settingsController: AppSettingsController(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add kid profile'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText), 'Mina');
    await tester.tap(find.text('🤩'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Mina'), findsOneWidget);
    expect(find.text('🤩'), findsOneWidget);
  });

  testWidgets('removes a kid profile', (WidgetTester tester) async {
    await tester.pumpWidget(
      BrushingApp(
        availableCameras: const [],
        settingsController: AppSettingsController(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add kid profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'Mina');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Mina'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Mina'), findsNothing);
    expect(find.text('Kid'), findsOneWidget);
  });

  testWidgets('renames a kid profile', (WidgetTester tester) async {
    await tester.pumpWidget(
      BrushingApp(
        availableCameras: const [],
        settingsController: AppSettingsController(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add kid profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'Mina');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Mina'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'Lina');
    await tester.tap(find.text('😊'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Mina'), findsNothing);
    expect(find.text('Lina'), findsOneWidget);
    expect(find.text('😊'), findsOneWidget);
  });
}
