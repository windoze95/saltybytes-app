import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:saltybytes_app/core/providers/finder_provider.dart';
import 'package:saltybytes_app/core/providers/search_provider.dart';
import 'package:saltybytes_app/core/theme/app_theme.dart';
import 'package:saltybytes_app/features/finder/finder_run_screen.dart';
import 'package:saltybytes_app/features/finder/widgets/finder_shortlist_card.dart';

import '../../helpers/test_helpers.dart';

/// Finder notifier that holds a scripted [FinderRunState] and does nothing on
/// run/refine, so tests can drive the run screen from a fixed state.
class _FakeFinderNotifier extends FinderNotifier {
  _FakeFinderNotifier(FinderRunState initial)
      : super(apiClient: MockApiClient()) {
    state = initial;
  }

  @override
  Future<void> run(FinderFacets facets) async {}

  @override
  Future<void> refine(String constraint) async {}
}

FinderResultItem _item({
  String title = 'Creamy Chicken Pasta',
  String url = 'https://example.com/ccp',
  String? reason = 'Quick and kid-friendly',
  String safetyStatus = 'safe',
  String memberName = 'Junior',
}) {
  return FinderResultItem.fromJson({
    'result': {
      'title': title,
      'source_url': url,
      'source_domain': 'example.com',
      'rating': 4.6,
      'image_url': '', // null image keeps real HTTP out of the test
      'description': 'Weeknight chicken pasta',
    },
    if (reason != null) 'reason': reason,
    'safety': [
      {'member_name': memberName, 'status': safetyStatus, 'note': ''},
    ],
  });
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  WebSearchResult? pushedPreview;

  Widget appFor(FinderRunState scripted) {
    pushedPreview = null;
    final router = GoRouter(
      initialLocation: '/find/run',
      routes: [
        GoRoute(
          path: '/find/run',
          builder: (_, __) => const FinderRunScreen(facets: FinderFacets()),
        ),
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
      ],
    );

    return ProviderScope(
      overrides: [
        finderProvider.overrideWith((ref) => _FakeFinderNotifier(scripted)),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }

  final shortlistState = FinderRunState(
    phase: FinderPhase.done,
    narration: const [
      'Searching “chicken pasta”…',
      'Found 3 real recipes',
      'Checking these against your family…',
    ],
    items: [_item()],
    refineChips: const ['quicker', 'cheaper', 'more veg', 'swap protein'],
  );

  // Pumps the run screen and advances past the staggered card / narration
  // entrance animations without pumpAndSettle (flutter_animate never settles).
  Future<void> pumpRun(WidgetTester tester, FinderRunState state) async {
    await tester.pumpWidget(appFor(state));
    await tester.pump(); // fires the post-frame run() (a no-op fake)
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('FinderRunScreen', () {
    testWidgets('streams narration lines and reveals the ranked shortlist',
        (tester) async {
      await pumpRun(tester, shortlistState);

      expect(find.textContaining('Found 3 real recipes'), findsOneWidget);
      expect(find.textContaining('Checking these against your family'),
          findsOneWidget);

      // Curated single-column list of the finder card.
      expect(find.byType(FinderShortlistCard), findsOneWidget);
      expect(find.text('Creamy Chicken Pasta'), findsOneWidget);
      // The rationale is the hero subtitle.
      expect(find.text('Quick and kid-friendly'), findsOneWidget);
      // Meta row: rating + aggregate family-safety summary (no cook time).
      expect(find.text('4.6'), findsOneWidget);
      expect(find.text('Family-safe'), findsOneWidget);

      // Tap-to-refine chips.
      expect(find.widgetWithText(ActionChip, 'quicker'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'swap protein'), findsOneWidget);
    });

    testWidgets('safety summary flags avoid for a member', (tester) async {
      final avoidState = FinderRunState(
        phase: FinderPhase.done,
        narration: const ['Found 1 real recipe'],
        items: [_item(safetyStatus: 'avoid', memberName: 'Junior')],
      );

      await pumpRun(tester, avoidState);

      expect(find.text('Avoid for Junior'), findsOneWidget);
      expect(find.text('Family-safe'), findsNothing);
    });

    testWidgets('tapping a shortlist card pushes the existing preview route',
        (tester) async {
      await pumpRun(tester, shortlistState);

      // warnIfMissed: the card is wrapped in flutter_animate's opacity/transform
      // (the entrance animation), which confuses tap()'s hit-test-first check
      // even though the pointer still routes to the card's InkWell.
      await tester.tap(find.byType(FinderShortlistCard), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('preview-Creamy Chicken Pasta'), findsOneWidget);
      expect(pushedPreview, isNotNull);
      expect(pushedPreview!.sourceUrl, 'https://example.com/ccp');
    });

    testWidgets('empty state offers broaden chips and never implies invention',
        (tester) async {
      const emptyState = FinderRunState(
        phase: FinderPhase.empty,
        narration: ['Searching…', 'Found 0 real recipes'],
        broaden: ['comfort food', '30-minute meals'],
      );

      await pumpRun(tester, emptyState);

      expect(find.text("Couldn't find a great match"), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'comfort food'), findsOneWidget);
      expect(
          find.widgetWithText(ActionChip, '30-minute meals'), findsOneWidget);
      expect(find.byType(FinderShortlistCard), findsNothing);
    });

    testWidgets('limit state shows the upgrade affordance', (tester) async {
      const limitState = FinderRunState(
        phase: FinderPhase.error,
        isLimitReached: true,
        error: 'You’ve reached your search limit.',
      );

      await pumpRun(tester, limitState);

      expect(find.text('Search limit reached'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Upgrade to Premium'),
          findsOneWidget);
    });
  });
}
