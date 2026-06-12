import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/allergen_provider.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockApiClient apiClient;

  setUp(() {
    apiClient = MockApiClient();
  });

  group('AllergenAnalyzer.analyze', () {
    test('POSTs the /allergens/analyze route and unwraps the envelope',
        () async {
      when(() => apiClient.post(any(), options: any(named: 'options')))
          .thenAnswer(
        (_) async => fakeResponse<dynamic>({
          'analysis': testAllergenAnalysisJson(recipeId: 123),
        }),
      );

      final analyzer = AllergenAnalyzer(apiClient: apiClient);
      final analysis = await analyzer.analyze('123');

      // Contract C4: analyze route is POST /v1/recipes/:id/allergens/analyze
      verify(() => apiClient.post(
            '/v1/recipes/123/allergens/analyze',
            options: any(named: 'options'),
          )).called(1);

      expect(analysis.recipeId, '123');
      expect(analysis.containsGluten, true);
      expect(analysis.unsafeForProfiles, ['1']);
    });
  });

  group('allergenAnalysisProvider', () {
    test('GETs the cached analysis and unwraps the envelope', () async {
      when(() => apiClient.get(ApiEndpoints.allergenAnalysis('55')))
          .thenAnswer(
        (_) async => fakeResponse<dynamic>({
          'analysis': testAllergenAnalysisJson(recipeId: 55),
        }),
      );

      final container = ProviderContainer(overrides: [
        apiClientProvider.overrideWithValue(apiClient),
      ]);
      addTearDown(container.dispose);

      final analysis =
          await container.read(allergenAnalysisProvider('55').future);

      expect(analysis.recipeId, '55');
      expect(analysis.detectedAllergens, contains('Dairy'));
      verify(() => apiClient.get('/v1/recipes/55/allergens')).called(1);
    });

    test('surfaces errors for missing analyses', () async {
      when(() => apiClient.get(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/recipes/9/allergens'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/recipes/9/allergens'),
            statusCode: 404,
          ),
        ),
      );

      final container = ProviderContainer(overrides: [
        apiClientProvider.overrideWithValue(apiClient),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(allergenAnalysisProvider('9').future),
        throwsA(isA<DioException>()),
      );
    });
  });
}
