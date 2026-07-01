import 'package:flutter/material.dart';
// Family is also exported by Riverpod; hide it so `Family` = our model.
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/core/providers/finder_provider.dart';
import 'package:saltybytes_app/core/providers/search_provider.dart';
import 'package:saltybytes_app/core/theme/app_theme.dart';
import 'package:saltybytes_app/features/search/search_screen.dart';
import 'package:saltybytes_app/features/search/widgets/agent_controls.dart';
import 'package:saltybytes_app/features/search/widgets/finder_shortlist_card.dart';
import 'package:saltybytes_app/models/family.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_helpers.dart';

/// Search notifier that holds a scripted [SearchState] and no-ops the network
/// (search/loadMore/refine); the state mutators (setFacets/setViewMode/...) are
/// inherited so UI interactions still reflect.
class _FakeSearchNotifier extends SearchNotifier {
  _FakeSearchNotifier(SearchState initial) : super(apiClient: MockApiClient()) {
    state = initial;
  }

  @override
  Future<void> search() async {}

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> refine(String constraint) async {}
}

WebSearchResult _result({
  String title = 'Creamy Chicken Pasta',
  String url = 'https://x.com/ccp',
  String? reason,
}) =>
    WebSearchResult(
      title: title,
      sourceUrl: url,
      sourceDomain: 'x.com',
      reason: reason,
    );

WebSearchResult? pushedPreview;

GoRouter _router() {
  pushedPreview = null;
  return GoRouter(
    initialLocation: '/search',
    routes: [
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(
        path: '/search/preview',
        builder: (_, state) {
          pushedPreview = state.extra as WebSearchResult?;
          return Scaffold(body: Text('preview-${pushedPreview?.title}'));
        },
      ),
      GoRoute(
        path: '/settings/subscription',
        name: 'subscription',
        builder: (_, __) => const Scaffold(body: Text('sub-stub')),
      ),
      GoRoute(
        path: '/family',
        name: 'family',
        builder: (_, __) => const Scaffold(body: Text('family-stub')),
      ),
      GoRoute(
        path: '/import',
        name: 'import',
        builder: (_, __) => const Scaffold(body: Text('import-stub')),
      ),
    ],
  );
}

/// Fresh (real) notifier app: agent-mode input interactions.
Widget _realApp() {
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(MockApiClient()),
      // Unauthenticated → familyProvider returns null (no dietary chip, no API).
      authStateProvider
          .overrideWith(() => FakeAuthNotifier(AuthStatus.unauthenticated)),
    ],
    child:
        MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: _router()),
  );
}

/// Scripted-state app: results display, view toggle, card tap.
Widget _scriptedApp(SearchState scripted) {
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(MockApiClient()),
      authStateProvider
          .overrideWith(() => FakeAuthNotifier(AuthStatus.unauthenticated)),
      searchProvider.overrideWith((ref) => _FakeSearchNotifier(scripted)),
    ],
    child:
        MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: _router()),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('SearchScreen — agent input', () {
    testWidgets('shows facet pills, Surprise me, and the Find CTA',
        (tester) async {
      await tester.pumpWidget(_realApp());
      await _settle(tester);

      expect(find.widgetWithText(ChoiceChip, 'Weeknight'), findsOneWidget);
      expect(find.text('Surprise me'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Find recipes'), findsOneWidget);
      // Agent is the default mode.
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    });

    testWidgets('tapping a facet chip selects it', (tester) async {
      await tester.pumpWidget(_realApp());
      await _settle(tester);

      ChoiceChip chip() => tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Weeknight'));
      expect(chip().selected, isFalse);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Weeknight'));
      await tester.pump();
      expect(chip().selected, isTrue);
    });

    testWidgets('turning the agent off shows the search bar + collapsed filters',
        (tester) async {
      await tester.pumpWidget(_realApp());
      await _settle(tester);

      await tester.tap(find.byType(Switch));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Filters (0)'), findsOneWidget);
      // The pills are now hidden behind the collapsed expander.
      expect(find.widgetWithText(FilledButton, 'Find recipes'), findsNothing);
    });
  });

  group('SearchScreen — agent results', () {
    final agentResults = SearchState(
      agentMode: true,
      hasSearched: true,
      phase: FinderPhase.done,
      results: [_result(reason: 'Quick + kid-friendly')],
      narration: const [
        'Found 3 real recipes',
        'Checking these against your family…',
      ],
      refineChips: const ['quicker', 'cheaper'],
      hasMore: false,
    );

    testWidgets('renders narration, the shortlist card, and refine chips',
        (tester) async {
      await tester.pumpWidget(_scriptedApp(agentResults));
      await _settle(tester);

      expect(find.textContaining('Found 3 real recipes'), findsOneWidget);
      expect(find.byType(FinderShortlistCard), findsOneWidget);
      expect(find.text('Creamy Chicken Pasta'), findsOneWidget);
      expect(find.text('Quick + kid-friendly'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'quicker'), findsOneWidget);
    });

    testWidgets('tapping a shortlist card opens the preview route',
        (tester) async {
      await tester.pumpWidget(_scriptedApp(agentResults));
      await _settle(tester);

      await tester.tap(find.byType(FinderShortlistCard), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('preview-Creamy Chicken Pasta'), findsOneWidget);
      expect(pushedPreview?.sourceUrl, 'https://x.com/ccp');
    });

    testWidgets('the view toggle switches to the immersive full-screen view',
        (tester) async {
      await tester.pumpWidget(_scriptedApp(agentResults));
      await _settle(tester);

      // List view first: no immersive "Preview Recipe" button.
      expect(find.text('Preview Recipe'), findsNothing);

      // In list view the toggle shows the "switch to immersive" icon.
      await tester.tap(find.byIcon(Icons.view_day_outlined));
      await _settle(tester);

      expect(find.text('Preview Recipe'), findsOneWidget);
    });
  });

  group('familyDietSummary', () {
    test('summarizes allergies + restrictions across members', () {
      final family = Family.fromJson(testFamilyJson());
      final summary = familyDietSummary(family);
      expect(summary, contains('no peanuts'));
      expect(summary, contains('vegetarian'));
    });

    test('returns null when there is no family', () {
      expect(familyDietSummary(null), isNull);
    });
  });
}
