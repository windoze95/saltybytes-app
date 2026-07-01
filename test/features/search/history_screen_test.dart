import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/providers/finder_provider.dart';
import 'package:saltybytes_app/core/providers/history_provider.dart';
import 'package:saltybytes_app/core/providers/search_provider.dart';
import 'package:saltybytes_app/core/theme/app_theme.dart';
import 'package:saltybytes_app/features/search/history_screen.dart';
import 'package:saltybytes_app/models/finder_session.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_helpers.dart';

/// History notifier that returns canned sessions and records deletes.
class _FakeHistoryNotifier extends FinderHistoryNotifier {
  _FakeHistoryNotifier(this._sessions);

  final List<FinderSession> _sessions;
  final List<int> deleted = [];

  @override
  Future<List<FinderSession>> build() async => _sessions;

  @override
  Future<void> delete(int id) async {
    deleted.add(id);
    state = AsyncData(
        (state.valueOrNull ?? []).where((s) => s.id != id).toList());
  }
}

GoRouter _router() => GoRouter(
      initialLocation: '/search/history',
      routes: [
        GoRoute(
            path: '/search/history',
            builder: (_, __) => const HistoryScreen()),
        GoRoute(
            path: '/search',
            builder: (_, __) => const Scaffold(body: Text('search-stub'))),
      ],
    );

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final sessions = [
    FinderSession.fromJson(testFinderSessionJson(id: 1, title: 'chicken dinner')),
    FinderSession.fromJson(testFinderSessionJson(id: 2, title: 'pasta night')),
  ];

  ProviderContainer pumpApp(WidgetTester tester, _FakeHistoryNotifier fake) {
    final container = ProviderContainer(overrides: [
      apiClientProvider.overrideWithValue(MockApiClient()),
      finderHistoryProvider.overrideWith(() => fake),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  testWidgets('lists saved sessions with title + result count', (tester) async {
    final fake = _FakeHistoryNotifier(sessions);
    final container = pumpApp(tester, fake);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
          theme: AppTheme.lightTheme, routerConfig: _router()),
    ));
    await _settle(tester);

    expect(find.text('chicken dinner'), findsOneWidget);
    expect(find.text('pasta night'), findsOneWidget);
    expect(find.textContaining('1 recipe'), findsWidgets);
  });

  testWidgets('tapping a row restores it into Search and navigates',
      (tester) async {
    final fake = _FakeHistoryNotifier(sessions);
    final container = pumpApp(tester, fake);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
          theme: AppTheme.lightTheme, routerConfig: _router()),
    ));
    await _settle(tester);

    await tester.tap(find.text('chicken dinner'));
    await _settle(tester);

    // Navigated to Search.
    expect(find.text('search-stub'), findsOneWidget);

    // Search state repopulated from the session (no re-run).
    final state = container.read(searchProvider);
    expect(state.agentMode, isTrue);
    expect(state.phase, FinderPhase.done);
    expect(state.hasSearched, isTrue);
    expect(state.results, isNotEmpty);
    expect(state.facets.cuisine, 'Italian');
  });

  testWidgets('swiping a row deletes the session', (tester) async {
    final fake = _FakeHistoryNotifier(sessions);
    final container = pumpApp(tester, fake);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
          theme: AppTheme.lightTheme, routerConfig: _router()),
    ));
    await _settle(tester);

    // Drag well past the dismiss threshold, then let the dismiss + resize
    // animations complete (this screen has no perpetual animations).
    await tester.drag(find.text('chicken dinner'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(fake.deleted, [1]);
    expect(find.text('chicken dinner'), findsNothing);
  });
}
