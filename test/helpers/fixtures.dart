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

/// Mirrors the GET /v1/recipes/:id/tree contract: a flat node list (children
/// are rebuilt client-side from parent_id). Default shape is a 3-node tree:
/// root "original" (active) with two child branches.
Map<String, dynamic> testRecipeTreeJson({
  int treeId = 1,
  String recipeId = 'r-1',
  int rootNodeId = 1,
  int? activeNodeId = 1,
  List<Map<String, dynamic>>? nodes,
}) =>
    {
      'tree_id': treeId,
      'recipe_id': recipeId,
      'root_node_id': rootNodeId,
      'active_node_id': activeNodeId,
      'nodes': nodes ??
          [
            testRecipeNodeJson(
              id: 1,
              branchName: 'original',
              summary: 'Initial recipe',
              isActive: activeNodeId == 1,
            ),
            testRecipeNodeJson(
              id: 2,
              parentId: 1,
              branchName: 'spicy-version',
              summary: 'Doubled the chili',
              type: 'fork',
              isActive: activeNodeId == 2,
            ),
            testRecipeNodeJson(
              id: 3,
              parentId: 1,
              branchName: 'vegan-version',
              summary: 'Swapped dairy for cashew cream',
              type: 'fork',
              isActive: activeNodeId == 3,
            ),
          ],
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

Map<String, dynamic> testIngredientAnalysisJson({
  String ingredientName = 'all-purpose flour',
  List<String>? commonAllergens,
  List<String>? possibleAllergens,
  List<String>? subIngredients,
  bool seedOilRisk = false,
  double confidence = 0.95,
}) =>
    {
      'ingredient_name': ingredientName,
      'common_allergens': commonAllergens ?? ['gluten', 'wheat'],
      'possible_allergens': possibleAllergens ?? [],
      'sub_ingredients': subIngredients ?? [],
      'seed_oil_risk': seedOilRisk,
      'confidence': confidence,
    };

Map<String, dynamic> testFamilySafetyCheckJson({
  dynamic memberId = 1,
  String memberName = 'Junior',
  String status = 'unsafe',
  List<String>? warnings,
}) =>
    {
      'member_id': memberId,
      'member_name': memberName,
      'status': status,
      'warnings': warnings ?? ['Contains peanuts - Junior has peanut allergy'],
    };

Map<String, dynamic> testAllergenAnalysisJson({
  dynamic id = 42,
  dynamic recipeId = 7,
  List<Map<String, dynamic>>? ingredientAnalyses,
  bool containsNuts = false,
  bool containsDairy = true,
  bool containsGluten = true,
  bool containsSoy = false,
  bool containsSeedOils = false,
  bool containsShellfish = false,
  bool containsEggs = false,
  List<dynamic>? safeForProfiles,
  List<dynamic>? unsafeForProfiles,
  double confidence = 0.92,
  bool requiresReview = false,
  bool isPremium = false,
  String promptVersion = 'v1',
  String disclaimer =
      'AI-generated analysis. Does not replace medical advice.',
  String? updatedAt,
}) =>
    {
      'id': id,
      'created_at': '2025-02-20T10:30:00.000Z',
      'updated_at': updatedAt ?? '2025-02-21T14:45:00.000Z',
      'recipe_id': recipeId,
      'node_id': null,
      'ingredient_analyses': ingredientAnalyses ??
          [
            testIngredientAnalysisJson(
              ingredientName: 'all-purpose flour',
              commonAllergens: ['gluten', 'wheat'],
            ),
            testIngredientAnalysisJson(
              ingredientName: 'mozzarella',
              commonAllergens: ['dairy'],
              possibleAllergens: ['lactose'],
              confidence: 0.9,
            ),
          ],
      'contains_nuts': containsNuts,
      'contains_dairy': containsDairy,
      'contains_gluten': containsGluten,
      'contains_soy': containsSoy,
      'contains_seed_oils': containsSeedOils,
      'contains_shellfish': containsShellfish,
      'contains_eggs': containsEggs,
      'safe_for_profiles': safeForProfiles ?? [2],
      'unsafe_for_profiles': unsafeForProfiles ?? [1],
      'confidence': confidence,
      'requires_review': requiresReview,
      'is_premium': isPremium,
      'prompt_version': promptVersion,
      'disclaimer': disclaimer,
    };

Map<String, dynamic> testAllergyJson({
  String name = 'peanuts',
  String severity = 'severe',
  List<String>? subForms,
  String notes = '',
}) =>
    {
      'name': name,
      'severity': severity,
      'sub_forms': subForms ?? [],
      'notes': notes,
    };

Map<String, dynamic> testDietaryProfileJson({
  dynamic id = 1,
  dynamic memberId = 1,
  List<Map<String, dynamic>>? allergies,
  List<String>? intolerances,
  List<String>? restrictions,
  List<String>? preferences,
  String medicalNotes = '',
}) =>
    {
      'id': id,
      'created_at': '2025-02-20T10:30:00.000Z',
      'updated_at': '2025-02-21T14:45:00.000Z',
      'member_id': memberId,
      'allergies': allergies ?? [testAllergyJson()],
      'intolerances': intolerances ?? ['lactose'],
      'restrictions': restrictions ?? ['vegetarian'],
      'preferences': preferences ?? ['no cilantro'],
      'medical_notes': medicalNotes,
    };

Map<String, dynamic> testFamilyMemberJson({
  dynamic id = 1,
  dynamic familyId = 1,
  String name = 'Junior',
  String relationship = 'son',
  dynamic userId,
  Map<String, dynamic>? dietaryProfile,
  bool includeProfile = true,
}) =>
    {
      'id': id,
      'created_at': '2025-02-20T10:30:00.000Z',
      'updated_at': '2025-02-21T14:45:00.000Z',
      'family_id': familyId,
      'name': name,
      'relationship': relationship,
      'user_id': userId,
      'dietary_profile':
          includeProfile ? (dietaryProfile ?? testDietaryProfileJson()) : null,
    };

Map<String, dynamic> testFamilyJson({
  dynamic id = 1,
  String name = 'The Smiths',
  dynamic ownerId = 99,
  List<Map<String, dynamic>>? members,
}) =>
    {
      'id': id,
      'created_at': '2025-02-20T10:30:00.000Z',
      'updated_at': '2025-02-21T14:45:00.000Z',
      'name': name,
      'owner_id': ownerId,
      'members': members ??
          [
            testFamilyMemberJson(id: 1, name: 'Junior', relationship: 'son'),
            testFamilyMemberJson(
              id: 2,
              name: 'Sarah',
              relationship: 'spouse',
              includeProfile: false,
            ),
          ],
    };

/// Mirrors GET /v1/subscription: models.Subscription has no json tags, so
/// Go serializes its field names (PascalCase) verbatim.
Map<String, dynamic> testSubscriptionJson({
  String tier = 'free',
  int allergenAnalysesUsed = 2,
  int webSearchesUsed = 7,
  int aiGenerationsUsed = 12,
  String monthlyResetAt = '2026-07-01T00:00:00Z',
}) =>
    {
      'ID': 1,
      'CreatedAt': '2026-01-01T00:00:00Z',
      'UpdatedAt': '2026-06-01T00:00:00Z',
      'DeletedAt': null,
      'UserID': 5,
      'Tier': tier,
      'ExpiresAt': null,
      'AllergenAnalysesUsed': allergenAnalysesUsed,
      'WebSearchesUsed': webSearchesUsed,
      'AIGenerationsUsed': aiGenerationsUsed,
      'MonthlyResetAt': monthlyResetAt,
    };

/// Mirrors a GET /v1/recipes/finder/sessions item / detail. `results` are flat
/// SearchResult objects; `intent` mirrors the FinderFacets wire shape.
Map<String, dynamic> testFinderSessionJson({
  int id = 1,
  String title = 'chicken dinner',
  String createdAt = '2026-07-01T10:00:00.000Z',
  Map<String, dynamic>? intent,
  List<Map<String, dynamic>>? results,
  List<String>? narration,
}) =>
    {
      'id': id,
      'title': title,
      'created_at': createdAt,
      'intent': intent ??
          {
            'cuisine': 'Italian',
            'protein': 'chicken',
            'use_what_i_have': <String>[],
            'surprise_me': false,
            'free_text': 'cozy',
          },
      'results': results ??
          [
            {
              'title': 'Result A',
              'source_url': 'https://x.com/a',
              'source_domain': 'x.com',
              'image_url': '',
              'rating': 4.5,
              'description': 'A tasty recipe',
            },
          ],
      'narration': narration ?? ['Searched for chicken', 'Found 1 recipe'],
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

Map<String, dynamic> testMultiRecipeCardJson({
  String title = 'Weeknight Pad Thai',
  String? imageUrl,
  String? description = 'A 30-minute pad thai for busy evenings',
  String? sourceUrl = 'https://example.com/roundup/pad-thai',
  String extractionStatus = 'done',
}) =>
    {
      'title': title,
      'image_url': imageUrl,
      'description': description,
      'source_url': sourceUrl,
      'extraction_status': extractionStatus,
    };

Map<String, dynamic> testMultiRecipeResolutionJson({
  String multiId = 'multi-abc-1',
  String sourceUrl = 'https://example.com/roundup',
  String status = 'resolved',
  List<Map<String, dynamic>>? recipes,
}) =>
    {
      'multi_id': multiId,
      'source_url': sourceUrl,
      'status': status,
      'recipes': recipes ??
          [
            testMultiRecipeCardJson(
              title: 'Weeknight Pad Thai',
              sourceUrl: 'https://example.com/roundup/pad-thai',
            ),
            testMultiRecipeCardJson(
              title: 'Crispy Spring Rolls',
              sourceUrl: 'https://example.com/roundup/spring-rolls',
            ),
          ],
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
