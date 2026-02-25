class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://api.saltybytes.ai';
  static const String apiVersion = '/v1';

  // Auth
  static const String login = '$apiVersion/auth/login';
  static const String register = '$apiVersion/auth/register';
  static const String refreshToken = '$apiVersion/auth/refresh';
  static const String logout = '$apiVersion/auth/logout';

  // User
  static const String userProfile = '$apiVersion/user/profile';
  static const String userSettings = '$apiVersion/user/settings';
  static const String userPersonalization = '$apiVersion/user/personalization';

  // Recipes
  static const String recipes = '$apiVersion/recipes';
  static String recipeById(String id) => '$apiVersion/recipes/$id';
  static String recipeVersions(String id) => '$apiVersion/recipes/$id/versions';
  static String recipeBranch(String id) => '$apiVersion/recipes/$id/branch';
  static String recipeFork(String id) => '$apiVersion/recipes/$id/fork';
  static String recipeMerge(String id) => '$apiVersion/recipes/$id/merge';

  // Recipe Similarity
  static String recipeSimilar(String id) => '$apiVersion/recipes/similar/$id';

  // Recipe Import
  static const String importRecipe = '$apiVersion/import';
  static const String importFromUrl = '$apiVersion/import/url';
  static const String importFromImage = '$apiVersion/import/image';

  // Allergens
  static String allergenAnalysis(String recipeId) =>
      '$apiVersion/recipes/$recipeId/allergens';

  // Cooking Mode
  static String cookingSession(String recipeId) =>
      '$apiVersion/recipes/$recipeId/cook';

  // Family
  static const String families = '$apiVersion/families';
  static String familyById(String id) => '$apiVersion/families/$id';
  static String familyMembers(String id) => '$apiVersion/families/$id/members';
  static String familyMember(String familyId, String memberId) =>
      '$apiVersion/families/$familyId/members/$memberId';

  // Search
  static const String search = '$apiVersion/search';
  static const String searchSuggestions = '$apiVersion/search/suggestions';

  // WebSocket
  static const String wsBaseUrl = 'wss://api.saltybytes.ai';
  static String wsCookingSession(String recipeId) =>
      '$wsBaseUrl$apiVersion/ws/cook/$recipeId';
}
