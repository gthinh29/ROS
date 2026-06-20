import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

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

  testWidgets('Renders MenuScreen when navigated to /table/T01',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CustomerApp()),
    );
    final BuildContext context = tester.element(find.byType(MaterialApp));
    context.go('/table/T01');
    await tester.pumpAndSettle();
    expect(find.text('Thực đơn'), findsOneWidget);
  });
}
