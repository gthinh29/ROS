import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:customer_web/main.dart';

void main() {
  testWidgets('App smoke test — renders without error',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CustomerApp()),
    );
    await tester.pumpAndSettle();
    // Should render the ErrorScreen (no tableId in test env)
    expect(find.text('Không tìm thấy bàn'), findsOneWidget);
  });
}
