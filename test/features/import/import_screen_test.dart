import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:saltybytes_app/features/import/import_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/import',
      routes: [
        GoRoute(path: '/import', builder: (_, __) => const ImportScreen()),
        GoRoute(
          path: '/import/url',
          builder: (_, __) => const Scaffold(body: Text('url-stub')),
        ),
        GoRoute(
          path: '/import/photo',
          builder: (_, __) => const Scaffold(body: Text('photo-stub')),
        ),
        GoRoute(
          path: '/import/text',
          builder: (_, __) => const Scaffold(body: Text('text-stub')),
        ),
        GoRoute(
          path: '/import/manual',
          builder: (_, __) => const Scaffold(body: Text('manual-stub')),
        ),
      ],
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    // The 2-column grid cards are ~370px tall; enlarge the surface so both
    // rows are built and tappable.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp.router(routerConfig: buildRouter()),
    );
    // Let the staggered card entrance animations finish (4 * 80ms + 300ms).
    await tester.pump(const Duration(milliseconds: 700));
  }

  group('ImportScreen', () {
    testWidgets('renders all four import options', (tester) async {
      await pumpScreen(tester);

      expect(find.text('From URL'), findsOneWidget);
      expect(find.text('From Photo'), findsOneWidget);
      expect(find.text('From Text'), findsOneWidget);
      expect(find.text('Manual Entry'), findsOneWidget);
    });

    for (final option in const [
      ('From URL', 'url-stub'),
      ('From Photo', 'photo-stub'),
      ('From Text', 'text-stub'),
      ('Manual Entry', 'manual-stub'),
    ]) {
      testWidgets('tapping ${option.$1} navigates to its import flow',
          (tester) async {
        await pumpScreen(tester);

        await tester.tap(find.text(option.$1));
        // Allow the pushed route transition to complete.
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text(option.$2), findsOneWidget);
      });
    }
  });
}
