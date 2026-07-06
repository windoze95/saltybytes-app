// Demo payloads for the STORE-SCREENSHOT harness (screenshot_main.dart).
//
// Everything here mirrors real API wire shapes via test/helpers/fixtures.dart.
// Images are served same-origin by the screenshot web server from /demo/
// (see tool/screenshots/) so CanvasKit never hits a CORS wall.
//
// Never ship or import this from lib/.
import '../helpers/fixtures.dart';

/// Same-origin demo image URL ("/demo/01_mac_and_cheese.jpg" next to the
/// served web build). Uri.base is the page URL on Flutter web.
String demoImg(String name) => '${Uri.base.origin}/demo/$name';

// ---------------------------------------------------------------------------
// The signed-in demo user: metric viewer so US-source recipes render the
// unit-conversion parenthetical ("2 cups (480 mL)") in the detail shot.
// ---------------------------------------------------------------------------

Map<String, dynamic> demoUser() => testUserJson(
      id: 'user-demo-1',
      username: 'alexcooks',
      email: 'alex@example.com',
      firstName: 'Alex',
      personalization: testPersonalizationJson(unitSystem: 'metric'),
    );

// ---------------------------------------------------------------------------
// Saved recipes (Home grid + detail + similar)
// ---------------------------------------------------------------------------

Map<String, dynamic> _saved({
  required String id,
  required String title,
  required String img,
  required int cookTime,
  List<String>? tags,
  String? sourceUrl,
  String? parentRecipeId,
  int? portions,
  String? portionSize,
  List<Map<String, dynamic>>? ingredients,
  List<String>? instructions,
}) =>
    testRecipeJson(
      id: id,
      title: title,
      ownerId: 'user-demo-1',
      imageUrl: demoImg(img),
      cookTimeMinutes: cookTime,
      tags: tags,
      sourceUrl: sourceUrl,
      parentRecipeId: parentRecipeId,
      portions: portions ?? 4,
      portionSize: portionSize ?? 'servings',
      ingredients: ingredients,
      instructions: instructions,
      createdAt: '2026-07-01T10:30:00.000Z',
      updatedAt: '2026-07-03T18:45:00.000Z',
    );

/// The hero recipe (Home card 1 + the recipe-detail shot). US-customary
/// source units with AI metric pairs on the cross-dimension ingredients, so a
/// metric viewer sees "2 cups (480 mL)"-style parentheticals.
Map<String, dynamic> demoDetailRecipe() => _saved(
      id: 'r1',
      title: 'Creamy Butternut Squash Mac & Cheese',
      img: '01_mac_and_cheese.jpg',
      cookTime: 45,
      tags: ['comfort food', 'fall', 'vegetarian'],
      portions: 6,
      portionSize: 'generous bowls',
      ingredients: [
        {
          'name': 'elbow macaroni',
          'amount': 1.0,
          'unit': 'lb',
          'original_text': '1 lb elbow macaroni',
        },
        {
          'name': 'butternut squash, cubed',
          'amount': 3.0,
          'unit': 'cups',
          'metric_amount': 420.0,
          'metric_unit': 'g',
          'original_text': '3 cups butternut squash, cubed',
        },
        {
          'name': 'whole milk',
          'amount': 2.0,
          'unit': 'cups',
          'metric_amount': 480.0,
          'metric_unit': 'mL',
          'original_text': '2 cups whole milk',
        },
        {
          'name': 'sharp cheddar, grated',
          'amount': 8.0,
          'unit': 'oz',
          'original_text': '8 oz sharp cheddar, grated',
        },
        {
          'name': 'Gruyère, grated',
          'amount': 4.0,
          'unit': 'oz',
          'original_text': '4 oz Gruyère, grated',
        },
        {
          'name': 'unsalted butter',
          'amount': 3.0,
          'unit': 'tbsp',
          'original_text': '3 tbsp unsalted butter',
        },
        {
          'name': 'all-purpose flour',
          'amount': 0.25,
          'unit': 'cup',
          'metric_amount': 30.0,
          'metric_unit': 'g',
          'original_text': '¼ cup all-purpose flour',
        },
        {
          'name': 'fresh thyme leaves',
          'amount': 1.0,
          'unit': 'tbsp',
          'original_text': '1 tbsp fresh thyme leaves',
        },
        {
          'name': 'freshly grated nutmeg',
          'amount': 0.25,
          'unit': 'tsp',
          'original_text': '¼ tsp freshly grated nutmeg',
        },
        {
          'name': 'toasted panko breadcrumbs',
          'amount': 0.5,
          'unit': 'cup',
          'metric_amount': 30.0,
          'metric_unit': 'g',
          'original_text': '½ cup toasted panko breadcrumbs',
        },
      ],
      instructions: [
        'Roast the butternut squash at 425°F until caramelized at the edges, about 25 minutes.',
        'Cook the macaroni in well-salted water to just shy of al dente; reserve a cup of pasta water.',
        'Melt the butter, whisk in the flour, and cook until nutty. Slowly whisk in the milk.',
        'Blend the roasted squash into the sauce until silky, then melt in both cheeses off the heat.',
        'Fold in the pasta, loosening with pasta water; season with thyme, nutmeg, salt, and pepper.',
        'Top with toasted panko and broil 2 minutes until golden and bubbling.',
      ],
    );

List<Map<String, dynamic>> demoSavedRecipes() => [
      demoDetailRecipe(),
      _saved(
        id: 'r2',
        title: 'One-Pot Chicken & Wild Rice Soup',
        img: '02_chicken_soup.jpg',
        cookTime: 40,
        tags: ['soup', 'one-pot'],
      ),
      _saved(
        id: 'r3',
        title: "Grandma's Sunday Pot Roast",
        img: '03_pot_roast.jpg',
        cookTime: 180,
        tags: ['family recipe', 'slow cooked'],
      ),
      _saved(
        id: 'r4',
        title: 'Crispy Salmon Rice Bowls',
        img: '04_salmon_bowl.jpg',
        cookTime: 25,
        tags: ['viral', 'weeknight'],
        sourceUrl: 'https://www.tiktok.com/@saltybite/video/7301',
      ),
      _saved(
        id: 'r5',
        title: 'Sheet-Pan Gnocchi with Burst Tomatoes',
        img: '05_gnocchi.jpg',
        cookTime: 30,
        tags: ['vegetarian', 'sheet-pan'],
      ),
      _saved(
        id: 'r6',
        title: 'Dairy-Free Garlic Butter Pasta',
        img: '06_garlic_pasta.jpg',
        cookTime: 25,
        tags: ['dairy-free', 'fork'],
        parentRecipeId: 'r1',
      ),
      _saved(
        id: 'r7',
        title: 'Thai Basil Chicken (Pad Krapow)',
        img: '07_pad_krapow.jpg',
        cookTime: 20,
        tags: ['thai', 'spicy'],
      ),
      _saved(
        id: 'r8',
        title: 'Blueberry Lemon Dutch Baby',
        img: '08_dutch_baby.jpg',
        cookTime: 35,
        tags: ['brunch', 'baking'],
      ),
    ];

List<Map<String, dynamic>> demoSimilarRecipes() => [
      _saved(
        id: 'r5',
        title: 'Sheet-Pan Gnocchi with Burst Tomatoes',
        img: '05_gnocchi.jpg',
        cookTime: 30,
      ),
      _saved(
        id: 'r6',
        title: 'Dairy-Free Garlic Butter Pasta',
        img: '06_garlic_pasta.jpg',
        cookTime: 25,
      ),
      _saved(
        id: 'r2',
        title: 'One-Pot Chicken & Wild Rice Soup',
        img: '02_chicken_soup.jpg',
        cookTime: 40,
      ),
    ];

// ---------------------------------------------------------------------------
// Family (dietary profiles) — Junior's dairy allergy makes the mac & cheese
// detail shot show the family-safety warning banner.
// ---------------------------------------------------------------------------

Map<String, dynamic> demoFamily() => testFamilyJson(
      id: 1,
      name: 'The Demo Kitchen',
      members: [
        testFamilyMemberJson(
          id: 1,
          name: 'Junior',
          relationship: 'son',
          dietaryProfile: testDietaryProfileJson(
            id: 1,
            memberId: 1,
            allergies: [
              testAllergyJson(name: 'dairy', severity: 'severe'),
            ],
            intolerances: [],
            restrictions: [],
            preferences: ['loves pasta'],
          ),
        ),
        testFamilyMemberJson(
          id: 2,
          name: 'Sarah',
          relationship: 'spouse',
          dietaryProfile: testDietaryProfileJson(
            id: 2,
            memberId: 2,
            allergies: [],
            intolerances: [],
            restrictions: ['vegetarian'],
            preferences: ['no cilantro'],
          ),
        ),
        testFamilyMemberJson(
          id: 3,
          name: 'Mia',
          relationship: 'daughter',
          dietaryProfile: testDietaryProfileJson(
            id: 3,
            memberId: 3,
            allergies: [
              testAllergyJson(name: 'peanuts', severity: 'moderate'),
            ],
            intolerances: [],
            restrictions: [],
            preferences: [],
          ),
        ),
      ],
    );

Map<String, dynamic> demoAllergenAnalysis() => testAllergenAnalysisJson(
      id: 1,
      recipeId: 'r1',
      containsDairy: true,
      containsGluten: true,
      containsNuts: false,
      unsafeForProfiles: [1],
      safeForProfiles: [2, 3],
      ingredientAnalyses: [
        testIngredientAnalysisJson(
          ingredientName: 'whole milk',
          commonAllergens: ['dairy'],
          confidence: 0.99,
        ),
        testIngredientAnalysisJson(
          ingredientName: 'sharp cheddar',
          commonAllergens: ['dairy'],
          possibleAllergens: ['lactose'],
          confidence: 0.98,
        ),
        testIngredientAnalysisJson(
          ingredientName: 'elbow macaroni',
          commonAllergens: ['gluten', 'wheat'],
          confidence: 0.97,
        ),
      ],
    );

// ---------------------------------------------------------------------------
// Agent search run ("cozy comfort food")
// ---------------------------------------------------------------------------

const demoCollectionTitle = "21 Comfort Foods I'm Making On Repeat This Fall";

Map<String, dynamic> _result({
  required String title,
  required String domain,
  required String img,
  required double rating,
  int? cookTime,
  String? description,
}) =>
    testWebSearchResultJson(
      title: title,
      sourceUrl: 'https://$domain/${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}',
      sourceDomain: domain,
      imageUrl: demoImg(img),
      rating: rating,
      cookTimeMinutes: cookTime,
      description: description,
    );

/// Wraps a flat result as a finder item ({result, reason, safety, via}).
Map<String, dynamic> _item(
  Map<String, dynamic> result, {
  String? reason,
  String? via,
  List<Map<String, dynamic>>? safety,
}) =>
    {
      'result': result,
      if (reason != null) 'reason': reason,
      if (via != null) 'via': via,
      if (safety != null) 'safety': safety,
    };

Map<String, dynamic> _safety(String member, String status, [String? note]) => {
      'member_name': member,
      'status': status,
      if (note != null) 'note': note,
    };

final _soup = _result(
  title: 'Marry Me Chicken Meatball Soup',
  domain: 'www.delish.com',
  img: '09_meatball_soup.jpg',
  rating: 4.8,
  cookTime: 45,
  description: 'Tender chicken meatballs in a creamy sun-dried tomato broth.',
);

final _stew = _result(
  title: 'Old-Fashioned Beef Stew',
  domain: 'www.allrecipes.com',
  img: '10_beef_stew.jpg',
  rating: 4.7,
  cookTime: 150,
  description: 'The classic: fork-tender beef, potatoes, and a rich gravy.',
);

final _lasagna = _result(
  title: 'Butternut Squash Lasagna with Sage',
  domain: 'www.feastingathome.com',
  img: '11_lasagna.jpg',
  rating: 4.9,
  cookTime: 75,
  description: 'Layers of roasted squash, mushrooms, and browned-butter sage.',
);

final _collection = testWebSearchResultJson(
  title: demoCollectionTitle,
  sourceUrl: 'https://www.delish.com/fall-comfort-food-recipes',
  sourceDomain: 'www.delish.com',
  imageUrl: demoImg('12_baked_potato.jpg'),
  rating: null,
  cookTimeMinutes: null,
  description: 'Warm, cozy, and on repeat all season long.',
);

final _potatoes = _result(
  title: 'French Onion Baked Potatoes',
  domain: 'www.thepioneerwoman.com',
  img: '12_baked_potato.jpg',
  rating: 4.6,
  cookTime: 60,
  description: 'Caramelized onions and melty Gruyère over crispy-skinned potatoes.',
);

final _beans = _result(
  title: 'Creamy Tuscan White Bean Skillet',
  domain: 'therealfooddietitians.com',
  img: '13_bean_skillet.jpg',
  rating: 4.7,
  cookTime: 30,
  description: 'A 30-minute vegetarian skillet with garlic, kale, and parmesan.',
);

// Mined out of the collection while digging.
final _ragu = _result(
  title: 'Slow-Cooker Short Rib Ragu',
  domain: 'www.delish.com',
  img: '14_ragu.jpg',
  rating: 4.9,
  cookTime: 240,
  description: 'Set-and-forget short ribs melted into a silky tomato ragu.',
);

final _pumpkinPasta = _result(
  title: 'Pumpkin Sage Brown Butter Pasta',
  domain: 'www.delish.com',
  img: '15_pumpkin_pasta.jpg',
  rating: 4.8,
  cookTime: 35,
  description: 'Nutty brown butter, pumpkin, and crispy sage in 35 minutes.',
);

/// The instant-paint candidates (SSE `results` event).
List<Map<String, dynamic>> demoInstantResults() => [
      _item(_soup),
      _item(_stew),
      _item(_lasagna),
      _item(_collection),
      _item(_potatoes),
      _item(_beans),
    ];

/// The ranked shortlist (SSE `shortlist`) — same results, enhanced in place
/// with the agent's reasons and family-safety checks.
List<Map<String, dynamic>> demoShortlist() => [
      _item(
        _soup,
        reason: 'One pot, brothy, and deeply cozy — exactly what you asked for.',
        safety: [
          _safety('Junior', 'caution', 'Contains cream — swap in coconut milk'),
          _safety('Sarah', 'unsafe', 'Contains chicken (vegetarian)'),
          _safety('Mia', 'safe'),
        ],
      ),
      _item(
        _stew,
        reason: 'The definition of comfort; it simmers while you do nothing.',
        safety: [
          _safety('Junior', 'safe'),
          _safety('Sarah', 'unsafe', 'Contains beef (vegetarian)'),
          _safety('Mia', 'safe'),
        ],
      ),
      _item(
        _lasagna,
        reason: 'Vegetarian and seasonal — the whole table can share it.',
        safety: [
          _safety('Junior', 'caution', 'Ricotta and mozzarella (dairy)'),
          _safety('Sarah', 'safe'),
          _safety('Mia', 'safe'),
        ],
      ),
      _item(_collection),
      _item(_potatoes),
      _item(_beans),
    ];

/// Recipes the agent folded out of the collection (SSE `expanded`).
List<Map<String, dynamic>> demoExpanded() => [
      _item(_ragu, via: demoCollectionTitle),
      _item(_pumpkinPasta, via: demoCollectionTitle),
    ];

/// The agent's final curated picks (SSE `picks`).
List<Map<String, dynamic>> demoPicks() => [
      _item(
        _soup,
        reason:
            'One pot, 45 minutes, and family-friendly with one easy swap — the coziest match here.',
      ),
      _item(
        _ragu,
        via: demoCollectionTitle,
        reason: 'Highest-rated find of the run; four hours of flavor, five minutes of work.',
      ),
      _item(
        _lasagna,
        reason: 'The vegetarian pick Sarah can share, without giving up the comfort factor.',
      ),
    ];

List<String> demoRefineChips() => [
      'Under 30 minutes',
      'Vegetarian',
      'One-pot only',
      'Lighter',
    ];

/// Preview payload for the tapped result (search-preview shot).
Map<String, dynamic> demoPreview() => testRecipePreviewJson(
      title: 'Marry Me Chicken Meatball Soup',
      cookTime: 45,
      portions: 6,
      portionSize: 'bowls',
      sourceUrl: _soup['source_url'] as String,
      hashtags: ['comfort food', 'soup', 'one-pot'],
      imagePrompt: null,
      linkedSuggestions: ['Crusty No-Knead Bread', 'Simple Green Salad'],
      ingredients: [
        testPreviewIngredientJson(name: 'ground chicken', amount: 1.0, unit: 'lb'),
        testPreviewIngredientJson(name: 'panko breadcrumbs', amount: 0.5, unit: 'cup'),
        testPreviewIngredientJson(name: 'parmesan, grated', amount: 0.5, unit: 'cup'),
        testPreviewIngredientJson(name: 'sun-dried tomatoes', amount: 0.33, unit: 'cup'),
        testPreviewIngredientJson(name: 'heavy cream', amount: 1.0, unit: 'cup'),
        testPreviewIngredientJson(name: 'chicken broth', amount: 6.0, unit: 'cups'),
        testPreviewIngredientJson(name: 'baby spinach', amount: 3.0, unit: 'cups'),
        testPreviewIngredientJson(name: 'garlic cloves, minced', amount: 4.0, unit: null),
      ],
      instructions: [
        'Mix the meatballs and roll into tablespoon-sized balls.',
        'Brown the meatballs in batches; set aside.',
        'Sauté garlic and sun-dried tomatoes, then pour in the broth.',
        'Simmer the meatballs through, 10–12 minutes.',
        'Stir in the cream and spinach until wilted; season and serve.',
      ],
    );

/// The WebSearchResult wire shape handed to the /search/preview route.
Map<String, dynamic> demoPreviewSourceResult() => _soup;
