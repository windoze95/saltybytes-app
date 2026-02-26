# SaltyBytes App

A Flutter mobile app for SaltyBytes — an AI-enhanced culinary experience.

## Getting Started

### Prerequisites

- Flutter SDK (stable channel)
- Xcode (for iOS builds)

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

### Build

```bash
flutter build ios --no-codesign
```

## Testing

All tests run offline — no network, API, or simulator required.

### Run all tests

```bash
flutter test
```

### Run tests with verbose output

```bash
flutter test --reporter expanded
```

### Run a specific test file

```bash
flutter test test/models/recipe_test.dart
flutter test test/providers/search_provider_test.dart
flutter test test/features/home/recipe_card_test.dart
```

### Run a specific test by name

```bash
flutter test --name "displays recipe title"
```

### Test structure

```
test/
├── helpers/
│   ├── fixtures.dart       # Factory functions for JSON maps and model instances
│   ├── test_helpers.dart   # MockDio, MockSecureStorage, provider container helpers
│   └── pump_helpers.dart   # Widget test wrappers (testApp, testAppScaffold)
├── models/
│   ├── recipe_test.dart    # Recipe, Ingredient, RecipeDef, RecipeNode serialization
│   ├── user_test.dart      # User, UserSettings, Personalization serialization
│   └── allergen_test.dart  # AllergenAnalysis, FamilySafetyCheck serialization
├── providers/
│   ├── search_provider_test.dart  # WebSearchResult, RecipePreview, PreviewIngredient
│   ├── recipe_provider_test.dart  # Response parsing, optimistic delete, pagination
│   └── auth_provider_test.dart    # AuthStatus, token storage, request body shapes
├── features/
│   ├── home/
│   │   ├── recipe_card_test.dart  # Title, cook time, servings, NEW badge, onTap
│   │   └── home_screen_test.dart  # Loading, grid, empty state, FAB, search
│   └── auth/
│       └── login_screen_test.dart # Fields, buttons, password toggle
└── widget_test.dart        # Smoke test (app builds without crashing)
```

### Writing new tests

Test helpers live in `test/helpers/`:

- **fixtures.dart**: `testRecipeJson()`, `testRecipe()`, `testUserJson()`, `testUser()`, `testAllergenAnalysisJson()`, `testWebSearchResultJson()`, `testRecipePreviewJson()` — return realistic data
- **test_helpers.dart**: `MockDio`, `MockSecureStorage`, `MockApiClient` (using mocktail), plus `createTestProviderContainer()` for Riverpod testing
- **pump_helpers.dart**: `testApp()` and `testAppScaffold()` — wrap widgets in `MaterialApp` + `ProviderScope` with proper theme/media context

For widget tests, use `tester.pump(const Duration(milliseconds: 100))` instead of `tester.pumpAndSettle()` — the app uses `flutter_animate` which creates infinitely repeating animations that prevent `pumpAndSettle` from ever completing.
