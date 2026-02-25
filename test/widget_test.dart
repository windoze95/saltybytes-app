import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:saltybytes_app/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SaltyBytesApp()),
    );
    // App should render something — no crash
    expect(find.byType(SaltyBytesApp), findsOneWidget);
  });
}
