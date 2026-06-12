import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/allergen.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// Unwraps the {"analysis": ...} envelope the backend uses for allergen
/// responses, falling back to the bare object for robustness.
AllergenAnalysis parseAnalysisEnvelope(Map<String, dynamic> data) {
  final analysis = data['analysis'];
  if (analysis is Map<String, dynamic>) {
    return AllergenAnalysis.fromJson(analysis);
  }
  return AllergenAnalysis.fromJson(data);
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
  return AllergenAnalyzer(apiClient: ref.watch(apiClientProvider));
});

class AllergenAnalyzer {
  const AllergenAnalyzer({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Runs AI allergen analysis (POST /v1/recipes/:id/allergens/analyze).
  Future<AllergenAnalysis> analyze(String recipeId) async {
    final response = await _apiClient.post(
      ApiEndpoints.allergenAnalyze(recipeId),
      options: Options(receiveTimeout: ApiTimeouts.aiGeneration),
    );
    return parseAnalysisEnvelope(response.data as Map<String, dynamic>);
  }
}
