/// Factory functions for realistic test data.
///
/// These mirror the exact JSON shapes produced by the SaltyBytes API
/// and the field names used in the generated .g.dart serializers.

Map<String, dynamic> testIngredientJson({
  String name = 'all-purpose flour',
  double? amount = 2.0,
  String? unit = 'cups',
  String? originalText,
  String? notes,
  bool optional = false,
  String? category = 'dry',
}) =>
    {
      'name': name,
      'amount': amount,
      'unit': unit,
      'original_text': originalText,
      'notes': notes,
      'optional': optional,
      'category': category,
    };

Map<String, dynamic> testRecipeJson({
  String id = 'recipe-abc-123',
  String title = 'Classic Margherita Pizza',
  String? description = 'A simple Italian pizza with fresh tomatoes and mozzarella',
  String ownerId = 'user-xyz-456',
  String? imageUrl = 'https://cdn.saltybytes.ai/images/pizza.jpg',
  List<Map<String, dynamic>>? ingredients,
  List<String>? instructions,
  List<String>? tags,
  String? cuisine = 'Italian',
  String? difficulty = 'medium',
  int? prepTimeMinutes = 30,
  int? cookTimeMinutes = 15,
  int servings = 4,
  String? sourceUrl,
  bool isPublic = false,
  List<String>? allergenTags,
  String currentBranch = 'main',
  String? parentRecipeId,
  int? version = 1,
  String? createdAt,
  String? updatedAt,
}) =>
    {
      'id': id,
      'title': title,
      'description': description,
      'ownerId': ownerId,
      'imageUrl': imageUrl,
      'ingredients': ingredients ??
          [
            testIngredientJson(name: 'pizza dough', amount: 1.0, unit: 'ball', category: 'dough'),
            testIngredientJson(name: 'mozzarella', amount: 200.0, unit: 'g', category: 'dairy'),
            testIngredientJson(name: 'fresh basil', amount: 6.0, unit: 'leaves', optional: true, category: 'herb'),
          ],
      'instructions': instructions ??
          [
            'Preheat oven to 475F',
            'Roll out the dough on a floured surface',
            'Add sauce, cheese, and toppings',
            'Bake for 12-15 minutes',
          ],
      'tags': tags ?? ['pizza', 'italian', 'vegetarian'],
      'cuisine': cuisine,
      'difficulty': difficulty,
      'prepTimeMinutes': prepTimeMinutes,
      'cookTimeMinutes': cookTimeMinutes,
      'servings': servings,
      'sourceUrl': sourceUrl,
      'isPublic': isPublic,
      'allergenTags': allergenTags ?? ['gluten', 'dairy'],
      'currentBranch': currentBranch,
      'parentRecipeId': parentRecipeId,
      'version': version,
      'createdAt': createdAt ?? '2025-02-20T10:30:00.000Z',
      'updatedAt': updatedAt ?? '2025-02-21T14:45:00.000Z',
    };

Map<String, dynamic> testRecipeNodeJson({
  String branch = 'main',
  int version = 1,
  String? parentBranch,
  int? parentVersion,
  List<Map<String, dynamic>>? children,
  String? commitMessage = 'Initial recipe import',
  String? createdAt,
}) =>
    {
      'branch': branch,
      'version': version,
      'parentBranch': parentBranch,
      'parentVersion': parentVersion,
      'children': children ?? [],
      'commitMessage': commitMessage,
      'createdAt': createdAt ?? '2025-02-20T10:30:00.000Z',
    };

Map<String, dynamic> testRecipeDefJson({
  String id = 'def-001',
  String recipeId = 'recipe-abc-123',
  String branch = 'main',
  int version = 1,
  String title = 'Classic Margherita Pizza',
  String? description = 'A simple Italian pizza',
  List<Map<String, dynamic>>? ingredients,
  List<String>? instructions,
  String? commitMessage = 'Initial version',
  String? authorId = 'user-xyz-456',
  String? createdAt,
}) =>
    {
      'id': id,
      'recipeId': recipeId,
      'branch': branch,
      'version': version,
      'title': title,
      'description': description,
      'ingredients': ingredients ??
          [
            testIngredientJson(name: 'pizza dough', amount: 1.0, unit: 'ball'),
          ],
      'instructions': instructions ?? ['Preheat oven', 'Bake for 12 minutes'],
      'commitMessage': commitMessage,
      'authorId': authorId,
      'createdAt': createdAt ?? '2025-02-20T10:30:00.000Z',
    };

Map<String, dynamic> testUserSettingsJson({
  String themeMode = 'dark',
  String measurementSystem = 'us_customary',
  int defaultServings = 4,
  bool notificationsEnabled = true,
  bool cookingModeWakelock = true,
}) =>
    {
      'themeMode': themeMode,
      'measurementSystem': measurementSystem,
      'defaultServings': defaultServings,
      'notificationsEnabled': notificationsEnabled,
      'cookingModeWakelock': cookingModeWakelock,
    };

Map<String, dynamic> testPersonalizationJson({
  List<String>? dietaryRestrictions,
  List<String>? cuisinePreferences,
  String skillLevel = 'intermediate',
  List<String>? allergens,
}) =>
    {
      'dietaryRestrictions': dietaryRestrictions ?? ['vegetarian'],
      'cuisinePreferences': cuisinePreferences ?? ['Italian', 'Japanese'],
      'skillLevel': skillLevel,
      'allergens': allergens ?? ['peanuts'],
    };

Map<String, dynamic> testUserJson({
  String id = 'user-xyz-456',
  String username = 'chefmike',
  String email = 'mike@example.com',
  String? displayName = 'Chef Mike',
  String? avatarUrl = 'https://cdn.saltybytes.ai/avatars/mike.jpg',
  Map<String, dynamic>? settings,
  Map<String, dynamic>? personalization,
  String? createdAt,
  String? updatedAt,
}) =>
    {
      'id': id,
      'username': username,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'settings': settings ?? testUserSettingsJson(),
      'personalization': personalization ?? testPersonalizationJson(),
      'createdAt': createdAt ?? '2025-01-15T08:00:00.000Z',
      'updatedAt': updatedAt ?? '2025-02-20T10:30:00.000Z',
    };

Map<String, dynamic> testAllergenInfoJson({
  String allergen = 'gluten',
  String severity = 'high',
  String source = 'wheat flour',
  String? ingredient = 'all-purpose flour',
  String? notes = 'Contains wheat gluten',
}) =>
    {
      'allergen': allergen,
      'severity': severity,
      'source': source,
      'ingredient': ingredient,
      'notes': notes,
    };

Map<String, dynamic> testFamilySafetyCheckJson({
  String memberId = 'member-001',
  String memberName = 'Junior',
  bool isSafe = false,
  List<String>? conflicts,
  List<String>? warnings,
}) =>
    {
      'memberId': memberId,
      'memberName': memberName,
      'isSafe': isSafe,
      'conflicts': conflicts ?? ['Contains peanuts - Junior has peanut allergy'],
      'warnings': warnings ?? ['May contain traces of tree nuts'],
    };

Map<String, dynamic> testAllergenAnalysisJson({
  String recipeId = 'recipe-abc-123',
  List<Map<String, dynamic>>? detectedAllergens,
  List<Map<String, dynamic>>? possibleAllergens,
  List<Map<String, dynamic>>? familySafetyChecks,
  bool isSafeForAll = false,
  String? analyzedAt,
}) =>
    {
      'recipeId': recipeId,
      'detectedAllergens': detectedAllergens ??
          [
            testAllergenInfoJson(allergen: 'gluten', severity: 'high', source: 'wheat flour'),
            testAllergenInfoJson(allergen: 'dairy', severity: 'high', source: 'mozzarella cheese', ingredient: 'mozzarella'),
          ],
      'possibleAllergens': possibleAllergens ??
          [
            testAllergenInfoJson(allergen: 'soy', severity: 'low', source: 'soy lecithin in dough', ingredient: 'pizza dough', notes: 'May be present in commercial dough'),
          ],
      'familySafetyChecks': familySafetyChecks ??
          [
            testFamilySafetyCheckJson(),
          ],
      'isSafeForAll': isSafeForAll,
      'analyzedAt': analyzedAt ?? '2025-02-21T14:45:00.000Z',
    };

Map<String, dynamic> testWebSearchResultJson({
  String title = 'Best Margherita Pizza Recipe',
  String? sourceUrl = 'https://www.seriouseats.com/margherita-pizza',
  String? sourceDomain = 'seriouseats.com',
  String? imageUrl = 'https://www.seriouseats.com/images/pizza.jpg',
  String? description = 'An authentic Neapolitan-style margherita pizza recipe',
  double? rating = 4.8,
  int? cookTimeMinutes = 20,
  List<Map<String, dynamic>>? familySafetyChecks,
}) =>
    {
      'title': title,
      'source_url': sourceUrl,
      'source_domain': sourceDomain,
      'image_url': imageUrl,
      'description': description,
      'rating': rating,
      'cook_time_minutes': cookTimeMinutes,
      'family_safety_checks': familySafetyChecks ?? [],
    };

Map<String, dynamic> testPreviewIngredientJson({
  String name = 'all-purpose flour',
  String? unit = 'cups',
  double? amount = 2.0,
}) =>
    {
      'name': name,
      'unit': unit,
      'amount': amount,
    };

Map<String, dynamic> testRecipePreviewJson({
  String title = 'Classic Margherita Pizza',
  List<Map<String, dynamic>>? ingredients,
  List<String>? instructions,
  int? cookTime = 15,
  int? portions = 4,
  String? portionSize = 'slices',
  String? sourceUrl = 'https://www.seriouseats.com/margherita-pizza',
  List<String>? hashtags,
  String? imagePrompt = 'A rustic margherita pizza with bubbling mozzarella',
  List<String>? linkedSuggestions,
}) =>
    {
      'title': title,
      'ingredients': ingredients ??
          [
            testPreviewIngredientJson(name: 'pizza dough', unit: 'ball', amount: 1.0),
            testPreviewIngredientJson(name: 'mozzarella', unit: 'g', amount: 200.0),
            testPreviewIngredientJson(name: 'basil leaves', unit: null, amount: null),
          ],
      'instructions': instructions ??
          [
            'Preheat oven to 475F',
            'Roll out dough',
            'Add toppings and bake',
          ],
      'cook_time': cookTime,
      'portions': portions,
      'portion_size': portionSize,
      'source_url': sourceUrl,
      'hashtags': hashtags ?? ['pizza', 'italian'],
      'image_prompt': imagePrompt,
      'linked_recipe_suggestions': linkedSuggestions ?? ['Garlic Bread', 'Tiramisu'],
    };
