/// Factory functions for realistic test data.
///
/// These mirror the exact JSON shapes produced by the SaltyBytes API
/// and the field names used in the generated .g.dart serializers.

Map<String, dynamic> testIngredientJson({
  String name = 'all-purpose flour',
  double? amount = 2.0,
  String? unit = 'cups',
  String? originalText,
}) =>
    {
      'name': name,
      'amount': amount,
      'unit': unit,
      'original_text': originalText,
    };

Map<String, dynamic> testRecipeJson({
  String id = 'recipe-abc-123',
  String title = 'Classic Margherita Pizza',
  String ownerId = 'user-xyz-456',
  String? imageUrl = 'https://cdn.saltybytes.ai/images/pizza.jpg',
  List<Map<String, dynamic>>? ingredients,
  List<String>? instructions,
  List<String>? tags,
  int? cookTimeMinutes = 15,
  String? sourceUrl,
  String unitSystem = 'us_customary',
  String status = 'ready',
  int? portions = 4,
  String? portionSize = '2 slices',
  String? parentRecipeId,
  String? createdAt,
  String? updatedAt,
}) =>
    {
      'id': id,
      'title': title,
      'ownerId': ownerId,
      'imageUrl': imageUrl,
      'ingredients': ingredients ??
          [
            testIngredientJson(name: 'pizza dough', amount: 1.0, unit: 'ball'),
            testIngredientJson(name: 'mozzarella', amount: 200.0, unit: 'g'),
            testIngredientJson(name: 'fresh basil', amount: 6.0, unit: 'leaves'),
          ],
      'instructions': instructions ??
          [
            'Preheat oven to 475F',
            'Roll out the dough on a floured surface',
            'Add sauce, cheese, and toppings',
            'Bake for 12-15 minutes',
          ],
      'tags': tags ?? ['pizza', 'italian', 'vegetarian'],
      'cookTimeMinutes': cookTimeMinutes,
      'sourceUrl': sourceUrl,
      'unitSystem': unitSystem,
      'status': status,
      'portions': portions,
      'portionSize': portionSize,
      'parentRecipeId': parentRecipeId,
      'createdAt': createdAt ?? '2025-02-20T10:30:00.000Z',
      'updatedAt': updatedAt ?? '2025-02-21T14:45:00.000Z',
    };

Map<String, dynamic> testRecipeNodeJson({
  int id = 1,
  int? parentId,
  String branchName = 'original',
  String summary = 'Initial recipe',
  String type = 'chat',
  bool isActive = true,
  bool isEphemeral = false,
  int? createdById = 1,
  String? createdAt,
  List<Map<String, dynamic>>? children,
}) =>
    {
      'id': id,
      'parent_id': parentId,
      'branch_name': branchName,
      'summary': summary,
      'type': type,
      'is_active': isActive,
      'is_ephemeral': isEphemeral,
      'created_by_id': createdById,
      'created_at': createdAt ?? '2025-02-20T10:30:00.000Z',
      'children': children ?? [],
    };

Map<String, dynamic> testUserSettingsJson({
  bool keepScreenAwake = true,
}) =>
    {
      'keep_screen_awake': keepScreenAwake,
    };

Map<String, dynamic> testPersonalizationJson({
  String unitSystem = 'us_customary',
  String requirements = '',
  String uid = '11111111-1111-1111-1111-111111111111',
}) =>
    {
      'unit_system': unitSystem,
      'requirements': requirements,
      'uid': uid,
    };

Map<String, dynamic> testUserJson({
  String id = 'user-xyz-456',
  String username = 'chefmike',
  String email = 'mike@example.com',
  String? firstName = 'Chef Mike',
  Map<String, dynamic>? settings,
  Map<String, dynamic>? personalization,
  String? createdAt,
  String? updatedAt,
}) =>
    {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
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
  String? metricUnit,
  double? metricAmount,
  String? originalText,
}) =>
    {
      'name': name,
      'unit': unit,
      'amount': amount,
      if (metricUnit != null) 'metric_unit': metricUnit,
      if (metricAmount != null) 'metric_amount': metricAmount,
      if (originalText != null) 'original_text': originalText,
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
  String? unitSystem,
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
      if (unitSystem != null) 'unit_system': unitSystem,
    };
