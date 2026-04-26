import 'package:flutter_test/flutter_test.dart';

import 'package:better_brushing/app.dart';

void main() {
  testWidgets('shows character selection and starts the flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BrushingApp(availableCameras: []));
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
}
