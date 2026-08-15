import 'package:flutter_test/flutter_test.dart';

import 'package:unimarket/app.dart';

void main() {
  testWidgets('App launches with splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const UniMarketApp());
    await tester.pump();

    expect(find.text('Uni Market'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.text('Discover campus deals'), findsOneWidget);
  });
}
