import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/search_provider.dart';
import 'package:saltybytes_app/features/search/search_screen.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late MockApiClient apiClient;
  late ProviderContainer container;
  late GoRouter router;
  WebSearchResult? pushedPreviewResult;

  setUp(() {
    apiClient = MockApiClient();
    container = ProviderContainer(overrides: [
      apiClientProvider.overrideWithValue(apiClient),
    ]);
    pushedPreviewResult = null;

    // imageUrl null keeps CachedNetworkImage (real HTTP) out of the test.
    when(() => apiClient.get(
          ApiEndpoints.search,
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => fakeResponse<dynamic>({
          'results': [
            testWebSearchResultJson(
              title: 'Best Margherita Pizza Recipe',
              imageUrl: null,
              sourceUrl: 'https://example.com/margherita',
              sourceDomain: 'example.com',
            ),
            testWebSearchResultJson(
              title: 'Detroit Style Pan Pizza',
              imageUrl: null,
              sourceUrl: 'https://example.com/detroit',
              sourceDomain: 'example.com',
            ),
          ],
          'has_more': false,
        }));

    router = GoRouter(
      initialLocation: '/search',
      routes: [
        GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
        GoRoute(
          path: '/search/preview',
          builder: (_, state) {
            pushedPreviewResult = state.extra as WebSearchResult?;
            return Scaffold(
              body: Text('preview-${pushedPreviewResult?.title}'),
            );
          },
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> performSearch(WidgetTester tester, [String query = 'pizza']) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('SearchScreen', () {
    testWidgets('shows the empty state before any search', (tester) async {
      await pumpScreen(tester);

      expect(
          find.text('Search for recipes across the web'), findsOneWidget);
      verifyNever(() => apiClient.get(
            ApiEndpoints.search,
            queryParameters: any(named: 'queryParameters'),
          ));
    });

    testWidgets('renders fixture results full-screen after a search',
        (tester) async {
      await pumpScreen(tester);
      await performSearch(tester);

      // Full-screen view shows the first result page.
      expect(find.text('Best Margherita Pizza Recipe'), findsOneWidget);
      expect(find.text('Preview Recipe'), findsOneWidget);
      expect(find.textContaining('example.com'), findsWidgets);

      final captured = verify(() => apiClient.get(
            ApiEndpoints.search,
            queryParameters: captureAny(named: 'queryParameters'),
          )).captured.single as Map<String, dynamic>;
      expect(captured['q'], 'pizza');
    });

    testWidgets('multi-recipe expansion replaces the card in the results',
        (tester) async {
      await pumpScreen(tester);
      await performSearch(tester);

      final notifier = container.read(searchProvider.notifier);
      final original = container.read(searchProvider).results.first;
      final resolution = MultiRecipeResolution.fromJson(
        testMultiRecipeResolutionJson(
          sourceUrl: original.sourceUrl!,
          recipes: [
            testMultiRecipeCardJson(
              title: 'Weeknight Pad Thai',
              sourceUrl: 'https://example.com/roundup/pad-thai',
            ),
            testMultiRecipeCardJson(
              title: 'Crispy Spring Rolls',
              sourceUrl: 'https://example.com/roundup/spring-rolls',
            ),
          ],
        ),
      );

      final insertedAt = notifier.replaceWithExpanded(original, resolution);
      await tester.pump(const Duration(milliseconds: 100));

      // The original card is gone; the first expanded entry renders in
      // its place at the returned index.
      expect(insertedAt, 0);
      final results = container.read(searchProvider).results;
      expect(results, hasLength(3));
      expect(results[0].title, 'Weeknight Pad Thai');
      expect(results[1].title, 'Crispy Spring Rolls');
      expect(find.text('Weeknight Pad Thai'), findsOneWidget);
      expect(find.text('Best Margherita Pizza Recipe'), findsNothing);
    });

    testWidgets('a still-extracting expanded card shows the Extracting badge',
        (tester) async {
      await pumpScreen(tester);
      await performSearch(tester);

      final notifier = container.read(searchProvider.notifier);
      final original = container.read(searchProvider).results.first;
      // status 'resolved' keeps the test from starting the background poll
      // (no pending timer); the first card is still mid-extraction so its
      // per-card badge should render.
      final resolution = MultiRecipeResolution.fromJson(
        testMultiRecipeResolutionJson(
          sourceUrl: original.sourceUrl!,
          recipes: [
            testMultiRecipeCardJson(
              title: 'Weeknight Pad Thai',
              sourceUrl: 'https://example.com/roundup/pad-thai',
              extractionStatus: 'extracting',
            ),
          ],
        ),
      );

      notifier.replaceWithExpanded(original, resolution);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Extracting…'), findsOneWidget);
    });

    testWidgets('tapping Preview Recipe pushes the preview with the result',
        (tester) async {
      await pumpScreen(tester);
      await performSearch(tester);

      await tester.tap(find.text('Preview Recipe'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      expect(
          find.text('preview-Best Margherita Pizza Recipe'), findsOneWidget);
      expect(pushedPreviewResult, isNotNull);
      expect(
          pushedPreviewResult!.sourceUrl, 'https://example.com/margherita');
    });
  });
}
