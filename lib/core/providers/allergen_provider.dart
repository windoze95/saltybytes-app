import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/allergen.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

final allergenAnalysisProvider =
    FutureProvider.family<AllergenAnalysis, String>((ref, recipeId) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.allergenAnalysis(recipeId));
  return AllergenAnalysis.fromJson(response.data as Map<String, dynamic>);
});

final allergenAnalyzeProvider = Provider<AllergenAnalyzer>((ref) {
  return AllergenAnalyzer(apiClient: ref.watch(apiClientProvider));
});

class AllergenAnalyzer {
  const AllergenAnalyzer({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<AllergenAnalysis> analyze(String recipeId) async {
    final response = await _apiClient.post(
      ApiEndpoints.allergenAnalysis(recipeId),
    );
    return AllergenAnalysis.fromJson(response.data as Map<String, dynamic>);
  }
}
