import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/allergen_provider.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/core/providers/family_provider.dart';
import 'package:saltybytes_app/models/family.dart' as models;

import '../helpers/fixtures.dart';
import '../helpers/test_helpers.dart';

/// Stubs the analyze POST for [recipeId] with empty profile lists, mirroring
/// the backend: plain analyze never fills safe/unsafe_for_profiles.
void stubAnalyze(MockApiClient apiClient, String recipeId) {
  when(() => apiClient.post(
        ApiEndpoints.allergenAnalyze(recipeId),
        options: any(named: 'options'),
      )).thenAnswer(
    (_) async => fakeResponse<dynamic>({
      'analysis': testAllergenAnalysisJson(
        recipeId: int.parse(recipeId),
        safeForProfiles: [],
        unsafeForProfiles: [],
      ),
    }),
  );
}

/// Stubs check-family for [recipeId]: Junior (1) unsafe, Sarah (2) safe,
/// Pat (3) caution.
void stubCheckFamily(MockApiClient apiClient, String recipeId) {
  when(() => apiClient.post(ApiEndpoints.allergenCheckFamily(recipeId)))
      .thenAnswer(
    (_) async => fakeResponse<dynamic>({
      'family_check': {
        'recipe_id': int.parse(recipeId),
        'member_results': [
          testFamilySafetyCheckJson(
            memberId: 1,
            memberName: 'Junior',
            status: 'unsafe',
          ),
          testFamilySafetyCheckJson(
            memberId: 2,
            memberName: 'Sarah',
            status: 'safe',
            warnings: [],
          ),
          testFamilySafetyCheckJson(
            memberId: 3,
            memberName: 'Pat',
            status: 'caution',
            warnings: ['mozzarella may contain lactose (intolerance: lactose)'],
          ),
        ],
        'disclaimer': 'AI-generated analysis.',
      },
    }),
  );
}

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

  group('AllergenAnalyzer family safety merge', () {
    test('analyze with a family triggers check-family and merges results',
        () async {
      stubAnalyze(apiClient, '123');
      stubCheckFamily(apiClient, '123');

      final analyzer = AllergenAnalyzer(
        apiClient: apiClient,
        loadFamily: () async => models.Family.fromJson(testFamilyJson()),
      );
      final analysis = await analyzer.analyze('123');

      verify(() => apiClient.post(ApiEndpoints.allergenCheckFamily('123')))
          .called(1);

      // "unsafe" members land in unsafeForProfiles; "safe" and "caution"
      // members are listed as safe (mirrors backend CheckFamily semantics).
      expect(analysis.unsafeForProfiles, ['1']);
      expect(analysis.safeForProfiles, ['2', '3']);
      expect(analysis.hasUnsafeMembers, true);
    });

    test('analyze without a family skips check-family', () async {
      stubAnalyze(apiClient, '123');

      final analyzer = AllergenAnalyzer(
        apiClient: apiClient,
        loadFamily: () async => null,
      );
      final analysis = await analyzer.analyze('123');

      verifyNever(
          () => apiClient.post(ApiEndpoints.allergenCheckFamily('123')));
      expect(analysis.safeForProfiles, isEmpty);
      expect(analysis.unsafeForProfiles, isEmpty);
      expect(analysis.hasUnsafeMembers, false);
    });

    test('analyze with a member-less family skips check-family', () async {
      stubAnalyze(apiClient, '123');

      final analyzer = AllergenAnalyzer(
        apiClient: apiClient,
        loadFamily: () async =>
            models.Family.fromJson(testFamilyJson(members: [])),
      );
      final analysis = await analyzer.analyze('123');

      verifyNever(
          () => apiClient.post(ApiEndpoints.allergenCheckFamily('123')));
      expect(analysis.hasUnsafeMembers, false);
    });

    test('keeps the analyze result when check-family fails', () async {
      stubAnalyze(apiClient, '123');
      when(() => apiClient.post(ApiEndpoints.allergenCheckFamily('123')))
          .thenThrow(
        DioException(
          requestOptions:
              RequestOptions(path: ApiEndpoints.allergenCheckFamily('123')),
          type: DioExceptionType.connectionError,
        ),
      );

      final analyzer = AllergenAnalyzer(
        apiClient: apiClient,
        loadFamily: () async => models.Family.fromJson(testFamilyJson()),
      );

      // Must not throw: check-family is best-effort.
      final analysis = await analyzer.analyze('123');

      expect(analysis.recipeId, '123');
      expect(analysis.containsGluten, true);
      expect(analysis.safeForProfiles, isEmpty);
      expect(analysis.unsafeForProfiles, isEmpty);
    });

    test('keeps the analyze result when the family lookup itself fails',
        () async {
      stubAnalyze(apiClient, '123');

      final analyzer = AllergenAnalyzer(
        apiClient: apiClient,
        loadFamily: () async => throw Exception('family fetch failed'),
      );
      final analysis = await analyzer.analyze('123');

      verifyNever(
          () => apiClient.post(ApiEndpoints.allergenCheckFamily('123')));
      expect(analysis.recipeId, '123');
    });
  });

  group('allergenAnalyzeProvider wiring', () {
    test('reads familyProvider through the container and merges member safety',
        () async {
      when(() => apiClient.get(ApiEndpoints.family)).thenAnswer(
        (_) async => fakeResponse<dynamic>({'family': testFamilyJson()}),
      );
      stubAnalyze(apiClient, '7');
      stubCheckFamily(apiClient, '7');

      final container = ProviderContainer(overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        authStateProvider.overrideWith(FakeAuthNotifier.new),
      ]);
      addTearDown(container.dispose);

      // Gotcha: familyProvider.future deadlocks without an active listener,
      // because the rebuild triggered by auth resolving never flushes.
      container.listen(familyProvider, (_, __) {});
      await container.read(authStateProvider.future);
      await Future<void>.delayed(Duration.zero);
      await container.read(familyProvider.future);

      final analysis =
          await container.read(allergenAnalyzeProvider).analyze('7');

      verify(() => apiClient.post(ApiEndpoints.allergenCheckFamily('7')))
          .called(1);
      expect(analysis.unsafeForProfiles, ['1']);
      expect(analysis.safeForProfiles, ['2', '3']);
    });
  });
}
