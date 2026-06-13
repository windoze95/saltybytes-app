import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/allergen.dart';
// Aliased: flutter_riverpod also exports a `Family` type.
import '../../models/family.dart' as family_models;
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'family_provider.dart';

/// Unwraps the {"analysis": ...} envelope the backend uses for allergen
/// responses, falling back to the bare object for robustness.
AllergenAnalysis parseAnalysisEnvelope(Map<String, dynamic> data) {
  final analysis = data['analysis'];
  if (analysis is Map<String, dynamic>) {
    return AllergenAnalysis.fromJson(analysis);
  }
  return AllergenAnalysis.fromJson(data);
}

/// Unwraps the {"family_check": {"member_results": [...]}} envelope from
/// POST /v1/recipes/:id/allergens/check-family into per-member results.
List<FamilySafetyCheck> parseFamilyCheckEnvelope(Map<String, dynamic> data) {
  final familyCheck = data['family_check'];
  final source = familyCheck is Map<String, dynamic> ? familyCheck : data;
  final results = source['member_results'];
  if (results is List) {
    return results
        .whereType<Map<String, dynamic>>()
        .map(FamilySafetyCheck.fromJson)
        .toList();
  }
  return const [];
}

/// Merges per-member check-family results into the analysis profile lists.
///
/// Mirrors backend semantics (service.CheckFamily): only members with status
/// "unsafe" land in `unsafe_for_profiles`; "safe" and "caution" members are
/// listed in `safe_for_profiles`.
AllergenAnalysis mergeFamilyCheck(
  AllergenAnalysis analysis,
  List<FamilySafetyCheck> memberResults,
) {
  if (memberResults.isEmpty) return analysis;
  return analysis.copyWith(
    safeForProfiles: [
      for (final result in memberResults)
        if (result.status != 'unsafe') result.memberId,
    ],
    unsafeForProfiles: [
      for (final result in memberResults)
        if (result.status == 'unsafe') result.memberId,
    ],
  );
}

/// Cached analysis for a recipe (GET /v1/recipes/:id/allergens).
final allergenAnalysisProvider =
    FutureProvider.family<AllergenAnalysis, String>((ref, recipeId) async {
  final apiClient = ref.watch(apiClientProvider);
  final response =
      await apiClient.get(ApiEndpoints.allergenAnalysis(recipeId));
  return parseAnalysisEnvelope(response.data as Map<String, dynamic>);
});

final allergenAnalyzeProvider = Provider<AllergenAnalyzer>((ref) {
  return AllergenAnalyzer(
    apiClient: ref.watch(apiClientProvider),
    // Read (not watch): the family is only needed at analyze time. By the
    // time a user can trigger an analysis, auth has resolved and the router
    // keeps authStateProvider listened, so awaiting the future here cannot
    // hit the "no listener" rebuild deadlock seen in bare test containers.
    loadFamily: () => ref.read(familyProvider.future),
  );
});

class AllergenAnalyzer {
  const AllergenAnalyzer({
    required ApiClient apiClient,
    Future<family_models.Family?> Function()? loadFamily,
  })  : _apiClient = apiClient,
        _loadFamily = loadFamily;

  final ApiClient _apiClient;
  final Future<family_models.Family?> Function()? _loadFamily;

  /// Runs AI allergen analysis (POST /v1/recipes/:id/allergens/analyze).
  ///
  /// Plain analyze never populates `safe_for_profiles` /
  /// `unsafe_for_profiles` — only POST .../allergens/check-family computes
  /// (and persists) member safety. So when the user has a family with
  /// members, a best-effort check-family follow-up runs and its per-member
  /// results are merged into the returned analysis so the recipe-detail
  /// warning banner and family-safety section can render.
  Future<AllergenAnalysis> analyze(String recipeId) async {
    final response = await _apiClient.post(
      ApiEndpoints.allergenAnalyze(recipeId),
      options: Options(receiveTimeout: ApiTimeouts.aiGeneration),
    );
    final analysis =
        parseAnalysisEnvelope(response.data as Map<String, dynamic>);
    return _withFamilySafety(recipeId, analysis);
  }

  /// Best-effort family safety merge: no family (or no members) skips the
  /// check; any error keeps the plain analyze result.
  Future<AllergenAnalysis> _withFamilySafety(
    String recipeId,
    AllergenAnalysis analysis,
  ) async {
    final loadFamily = _loadFamily;
    if (loadFamily == null) return analysis;

    try {
      final family = await loadFamily().timeout(const Duration(seconds: 5));
      if (family == null || family.members.isEmpty) {
        return analysis;
      }

      final response = await _apiClient.post(
        ApiEndpoints.allergenCheckFamily(recipeId),
      );
      final memberResults =
          parseFamilyCheckEnvelope(response.data as Map<String, dynamic>);
      return mergeFamilyCheck(analysis, memberResults);
    } catch (_) {
      // Check-family is supplementary; never fail the analyze flow over it.
      return analysis;
    }
  }
}
