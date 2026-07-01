class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://api.saltybytes.ai';
  static const String apiVersion = '/v1';

  // Auth
  static const String login = '$apiVersion/auth/login';
  static const String register = '$apiVersion/users';
  static const String refreshToken = '$apiVersion/auth/refresh';
  static const String logout = '$apiVersion/auth/logout';

  // User
  static const String userProfile = '$apiVersion/users/me';
  static const String userSettings = '$apiVersion/users/me/settings';
  static const String userPersonalization = '$apiVersion/users/me/personalization';
  static const String verifyToken = '$apiVersion/users/verify';

  // Recipes
  static const String recipes = '$apiVersion/recipes';
  static const String generateRecipe = '$apiVersion/recipes/chat';
  static String recipeById(String id) => '$apiVersion/recipes/$id';
  static String recipeChat(String id) => '$apiVersion/recipes/$id/chat';
  static String recipeFork(String id) => '$apiVersion/recipes/$id/fork';
  static String recipeBranch(String id) => '$apiVersion/recipes/$id/branch';
  static String recipeTree(String id) => '$apiVersion/recipes/$id/tree';
  static String recipeHistory(String id) => '$apiVersion/recipes/chat-history/$id';

  // Recipe Similarity
  static String recipeSimilar(String id) => '$apiVersion/recipes/similar/$id';

  // Recipe Import
  static const String importFromUrl = '$apiVersion/recipes/import/url';
  static const String importFromPhoto = '$apiVersion/recipes/import/photo';
  static const String importFromText = '$apiVersion/recipes/import/text';
  static const String importManual = '$apiVersion/recipes/import/manual';
  static const String importFromVideo = '$apiVersion/recipes/import/video';
  static String importVideoStatus(int jobId) =>
      '$apiVersion/recipes/import/video/$jobId';

  // Recipe Preview
  static const String previewFromUrl = '$apiVersion/recipes/preview/url';

  // Recipe Finder (guided, SSE-streamed real-recipe finder)
  static const String find = '$apiVersion/recipes/find';

  // Allergens
  static String allergenAnalysis(String recipeId) =>
      '$apiVersion/recipes/$recipeId/allergens';
  static String allergenAnalyze(String recipeId) =>
      '$apiVersion/recipes/$recipeId/allergens/analyze';
  static String allergenCheckFamily(String recipeId) =>
      '$apiVersion/recipes/$recipeId/allergens/check-family';

  // Cooking Mode
  static String cookingSession(String recipeId) =>
      '$apiVersion/recipes/$recipeId/cook';

  // Family
  static const String family = '$apiVersion/family';
  static const String familyMembers = '$apiVersion/family/members';
  static String familyMember(String memberId) =>
      '$apiVersion/family/members/$memberId';
  static String familyMemberDietary(String memberId) =>
      '$apiVersion/family/members/$memberId/dietary';
  static String familyMemberInterview(String memberId) =>
      '$apiVersion/family/members/$memberId/dietary/interview';

  // Search
  static const String search = '$apiVersion/recipes/search';
  static String resolveMultiRecipe(String multiId) =>
      '$apiVersion/recipes/search/resolve/$multiId';
  static const String checkMultiRecipe = '$apiVersion/recipes/search/check-multi';
  static const String warmUrls = '$apiVersion/recipes/search/warm';

  // Subscription
  static const String subscription = '$apiVersion/subscription';
  static const String subscriptionUpgrade = '$apiVersion/subscription/upgrade';

  // Images
  static const String imageUpload = '$apiVersion/images/upload';

  // WebSocket
  static const String wsBaseUrl = 'wss://api.saltybytes.ai';
  static String wsCookingSession(String recipeId) =>
      '$wsBaseUrl$apiVersion/ws/cook/$recipeId';
}
