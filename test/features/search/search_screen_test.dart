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

  group('SearchScreen — search-bar-first layout', () {
    testWidgets('agent mode leads with the bar; pills wait in the expander',
        (tester) async {
      await tester.pumpWidget(_realApp());
      await _settle(tester);

      // The search bar is front and center with the agent hint.
      expect(find.text('What are you in the mood for?'), findsOneWidget);
      // Tap-first on-ramps: Surprise me + mood chips.
      expect(find.text('Surprise me'), findsOneWidget);
      expect(find.text('cozy comfort food'), findsOneWidget);
      // Facet pills are behind the collapsed Filters expander.
      expect(find.text('Filters (0)'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Weeknight'), findsNothing);
      // Agent is the default mode.
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    });

    testWidgets('expanding Filters reveals the pills and taps select',
        (tester) async {
      await tester.pumpWidget(_realApp());
      await _settle(tester);

      await tester.tap(find.text('Filters (0)'));
      await _settle(tester);

      ChoiceChip chip() => tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Weeknight'));
      expect(chip().selected, isFalse);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Weeknight'));
      await tester.pump();
      expect(chip().selected, isTrue);
    });

    testWidgets('turning the agent off keeps the same layout, plainer',
        (tester) async {
      await tester.pumpWidget(_realApp());
      await _settle(tester);

      await tester.tap(find.byType(Switch));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Search for recipes...'), findsOneWidget);
      expect(find.text('Filters (0)'), findsOneWidget);
      // Agent-only on-ramps disappear in plain mode.
      expect(find.text('Surprise me'), findsNothing);
      expect(find.text('cozy comfort food'), findsNothing);
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
        'Picking the best matches…',
      ],
      refineChips: const ['quicker', 'cheaper'],
      hasMore: false,
    );

    testWidgets('renders the shortlist card and refine chips; the narration '
        'strip retires once the run is done', (tester) async {
      await tester.pumpWidget(
          _scriptedApp(agentResults.copyWith(viewMode: SearchViewMode.list)));
      await _settle(tester);

      expect(find.byType(FinderShortlistCard), findsOneWidget);
      expect(find.text('Creamy Chicken Pasta'), findsOneWidget);
      expect(find.text('Quick + kid-friendly'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'quicker'), findsOneWidget);
      // Done = the results speak; the live status line steps aside.
      expect(find.textContaining('Found 3 real recipes'), findsNothing);
    });

    testWidgets('tapping a shortlist card opens the preview route',
        (tester) async {
      await tester.pumpWidget(
          _scriptedApp(agentResults.copyWith(viewMode: SearchViewMode.list)));
      await _settle(tester);

      await tester.tap(find.byType(FinderShortlistCard), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('preview-Creamy Chicken Pasta'), findsOneWidget);
      expect(pushedPreview?.sourceUrl, 'https://x.com/ccp');
    });

    testWidgets('an in-flight run paints results live, tappable immediately',
        (tester) async {
      final working = SearchState(
        agentMode: true,
        hasSearched: true,
        phase: FinderPhase.digging,
        narration: const ['🔍 Searching…', '🍽 Opening ‘23 Best Dinners’…'],
        results: [
          _result(),
          _result(title: 'Two', url: 'https://x.com/2'),
        ],
        digging: const [DiggingCollection(title: '23 Best Dinners')],
        viewMode: SearchViewMode.list,
      );
      await tester.pumpWidget(_scriptedApp(working));
      await _settle(tester);

      // Results are on screen mid-run, with the live status + digging chip.
      expect(find.byType(FinderShortlistCard), findsNWidgets(2));
      expect(find.text('🍽 Opening ‘23 Best Dinners’…'), findsOneWidget);
      expect(find.textContaining('23 Best Dinners'), findsNWidgets(2));
    });

    testWidgets('before any result paints, the working view holds the floor',
        (tester) async {
      final working = SearchState(
        agentMode: true,
        hasSearched: true,
        isLoading: true,
        phase: FinderPhase.searching,
        narration: const ['🔍 Searching…'],
        viewMode: SearchViewMode.list,
      );
      await tester.pumpWidget(_scriptedApp(working));
      await _settle(tester);

      expect(find.text('Finding real recipes…'), findsOneWidget);
      expect(find.byType(FinderShortlistCard), findsNothing);
    });

    testWidgets('top picks render as their own section with provenance',
        (tester) async {
      final done = SearchState(
        agentMode: true,
        hasSearched: true,
        phase: FinderPhase.done,
        results: [
          _result(),
          _result(title: 'Two', url: 'https://x.com/2'),
        ],
        topPicks: [
          const WebSearchResult(
            title: 'Ground Beef Gyros',
            sourceUrl: 'https://x.com/gyros',
            sourceDomain: 'x.com',
            reason: 'Weeknight hero: 20 minutes, one skillet.',
            via: '23 Best Dinners',
          ),
        ],
        viewMode: SearchViewMode.list,
      );
      await tester.pumpWidget(_scriptedApp(done));
      await _settle(tester);

      expect(find.text('Top picks for you'), findsOneWidget);
      expect(find.text('Everything found'), findsOneWidget);
      expect(find.text('Ground Beef Gyros'), findsOneWidget);
      expect(find.textContaining('inside ‘23 Best Dinners’'), findsOneWidget);
      // Picks + the two non-pick results all render as cards.
      expect(find.byType(FinderShortlistCard), findsNWidgets(3));
    });

    testWidgets('the view toggle switches immersive → list', (tester) async {
      // Immersive is the default view.
      await tester.pumpWidget(_scriptedApp(agentResults));
      await _settle(tester);

      expect(find.text('Preview Recipe'), findsOneWidget);
      expect(find.byType(FinderShortlistCard), findsNothing);

      // In immersive view the toggle shows the "switch to list" icon.
      await tester.tap(find.byIcon(Icons.view_agenda_outlined));
      await _settle(tester);

      expect(find.byType(FinderShortlistCard), findsOneWidget);
      expect(find.text('Preview Recipe'), findsNothing);
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
