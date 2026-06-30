import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/search_provider.dart';
import 'package:saltybytes_app/features/search/search_preview_screen.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const sourceUrl = 'https://www.seriouseats.com/margherita-pizza';
  const cardImageUrl = 'https://www.seriouseats.com/images/pizza.jpg';

  final searchResult = WebSearchResult.fromJson(testWebSearchResultJson(
    title: 'Best Margherita Pizza Recipe',
    sourceUrl: sourceUrl,
    imageUrl: cardImageUrl,
  ));

  late MockApiClient apiClient;
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    apiClient = MockApiClient();
    container = ProviderContainer(overrides: [
      apiClientProvider.overrideWithValue(apiClient),
    ]);

    // Preview extraction: metric source recipe with dual-unit ingredients.
    when(() => apiClient.post(
          ApiEndpoints.previewFromUrl,
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => fakeResponse<dynamic>({
          'recipe': testRecipePreviewJson(
            title: 'Classic Margherita Pizza',
            unitSystem: 'metric',
            sourceUrl: sourceUrl,
            ingredients: [
              testPreviewIngredientJson(
                name: 'all-purpose flour',
                unit: 'cups',
                amount: 2.0,
                metricUnit: 'g',
                metricAmount: 250.0,
                originalText: '250 g all-purpose flour',
              ),
              testPreviewIngredientJson(
                name: 'mozzarella',
                unit: 'oz',
                amount: 7.0,
                metricUnit: 'g',
                metricAmount: 200.0,
              ),
            ],
          ),
        }));

    when(() => apiClient.post(
          ApiEndpoints.importManual,
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => fakeResponse<dynamic>(
        {'recipe': testRecipeJson(id: 'r-imported-1', title: 'Classic Margherita Pizza')}));

    router = GoRouter(
      initialLocation: '/search/preview',
      routes: [
        GoRoute(
          path: '/search/preview',
          builder: (_, __) => SearchPreviewScreen(searchResult: searchResult),
        ),
        GoRoute(
          path: '/recipe/:id',
          builder: (_, state) => Scaffold(
            body: Text('detail-${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('SearchPreviewScreen', () {
    testWidgets('renders the extracted preview with unit display',
        (tester) async {
      await pumpScreen(tester);

      expect(find.text('Classic Margherita Pizza'), findsOneWidget);
      expect(find.text('Ingredients'), findsOneWidget);
      // displayText formats whole-number amounts as integers with units.
      expect(find.text('2 cups all-purpose flour'), findsOneWidget);
      expect(find.text('7 oz mozzarella'), findsOneWidget);
      expect(find.text('Instructions'), findsOneWidget);
      expect(find.text('Preheat oven to 475F'), findsOneWidget);
      expect(find.text('Import Recipe'), findsOneWidget);

      final captured = verify(() => apiClient.post(
            ApiEndpoints.previewFromUrl,
            data: captureAny(named: 'data'),
            options: any(named: 'options'),
          )).captured.single as Map<String, dynamic>;
      expect(captured['url'], sourceUrl);
    });

    testWidgets('shows a saved-recipe badge on a cache hit', (tester) async {
      when(() => apiClient.post(
            ApiEndpoints.previewFromUrl,
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => fakeResponse<dynamic>({
            'recipe': testRecipePreviewJson(title: 'Cached Pizza'),
            'from_cache': true,
          }));

      await pumpScreen(tester);

      expect(find.text('Cached Pizza'), findsOneWidget);
      expect(find.text('Loaded from your saved recipes'), findsOneWidget);
    });

    testWidgets('shows progressive loading phases while extracting',
        (tester) async {
      final completer = Completer<Response<dynamic>>();
      when(() => apiClient.post(
            ApiEndpoints.previewFromUrl,
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) => completer.future);

      await pumpScreen(tester);
      // First honest phase.
      expect(find.text('Reading the page…'), findsOneWidget);

      // Advance the phase timer — it should move to the next phase.
      await tester.pump(const Duration(milliseconds: 3600));
      expect(find.text('Extracting the recipe…'), findsOneWidget);

      // Complete the request so the loading widget (and its timer) tears down.
      completer.complete(fakeResponse<dynamic>(
          {'recipe': testRecipePreviewJson(title: 'Done')}));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets(
        'import posts manual-import with unit_system and metric fields',
        (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Import Recipe'));
      await tester.pump(const Duration(milliseconds: 100));

      final captured = verify(() => apiClient.post(
            ApiEndpoints.importManual,
            data: captureAny(named: 'data'),
            options: any(named: 'options'),
          )).captured.single as Map<String, dynamic>;

      // Source unit system and provenance preserved (contract C6).
      expect(captured['unit_system'], 'metric');
      expect(captured['source_url'], sourceUrl);
      expect(captured['image_url'], cardImageUrl);
      expect(captured['title'], 'Classic Margherita Pizza');

      final ingredients = captured['ingredients'] as List;
      expect(ingredients, hasLength(2));
      final flour = ingredients.first as Map<String, dynamic>;
      expect(flour['name'], 'all-purpose flour');
      expect(flour['unit'], 'cups');
      expect(flour['amount'], 2.0);
      expect(flour['metric_unit'], 'g');
      expect(flour['metric_amount'], 250.0);
      expect(flour['original_text'], '250 g all-purpose flour');

      // Navigates to the created recipe after the import.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('detail-r-imported-1'), findsOneWidget);
    });

    testWidgets('failed import re-enables the button and shows a snackbar',
        (tester) async {
      when(() => apiClient.post(
            ApiEndpoints.importManual,
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => throw DioException(
            requestOptions: RequestOptions(path: ApiEndpoints.importManual),
          ));

      await pumpScreen(tester);
      await tester.tap(find.text('Import Recipe'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Failed to import'), findsOneWidget);
      final importButton = find.widgetWithText(FilledButton, 'Import Recipe');
      expect(tester.widget<FilledButton>(importButton).onPressed, isNotNull);
    });

    testWidgets('preview failure shows the error state with retry',
        (tester) async {
      when(() => apiClient.post(
            ApiEndpoints.previewFromUrl,
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => throw DioException(
            requestOptions: RequestOptions(path: ApiEndpoints.previewFromUrl),
            error: const ApiError(
              message: 'This website blocks automated access.',
              statusCode: 422,
              errorCode: 'site_blocked',
            ),
          ));

      await pumpScreen(tester);

      expect(find.text('Website blocked access'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Import Recipe'), findsNothing);
    });
  });
}
