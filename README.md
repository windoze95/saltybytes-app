# SaltyBytes

iOS client for [SaltyBytes](https://saltybytes.ai) — a recipe app that gets out of your way. Search the web for recipes without the ads and life stories, import from any source, generate with AI, and cook hands-free with voice-guided cooking mode.

Built with Flutter, Riverpod, and a deep hatred for recipe blogs.

> **See also:** [saltybytes-api](https://github.com/windoze95/saltybytes-api) — the Go backend that powers everything.

## Features

**Recipe Search & Discovery** — Search the web for recipes and get clean, card-based results. Tap any result for an instant AI-extracted preview — ingredients, steps, cook time — before committing to an import. No ads, no SEO spam, no scrolling past someone's vacation story.

**Multi-Source Import** — Import recipes from URLs, photos (point your camera at a cookbook), freeform text, or manual entry. The app extracts structured recipe data from anything you throw at it.

**AI Recipe Generation** — Can't find what you're looking for? Describe what you want in a chat and Claude generates a full recipe. Fork existing recipes into new variants, regenerate with feedback, and explore branching version history through an interactive recipe tree.

**Family Allergen Safety** — AI-powered ingredient analysis flags common allergens (dairy, nuts, shellfish, wheat, soy, sesame, etc.) with confidence scoring. Cross-reference any recipe against your family members' dietary profiles before cooking.

**Hands-Free Cooking Mode** — Real-time voice-guided cooking over WebSocket. Say "next step," ask "how much butter?", or request a substitution — the AI responds contextually with your recipe loaded. No touching your phone with raw-chicken hands.

**AI Dietary Interviews** — Set up dietary profiles for family members through natural conversation. The AI asks follow-up questions to build a comprehensive profile covering allergies, intolerances, and preferences.

## Architecture

```
Riverpod Providers → Services → Dio (API Client) → SaltyBytes API
```

| Layer | Purpose |
|-------|---------|
| `lib/features/` | Screens and widgets, organized by feature |
| `lib/providers/` | Riverpod state management and API integration |
| `lib/core/network/` | Dio HTTP client with auth interceptors and token refresh |
| `lib/core/storage/` | Secure token storage (flutter_secure_storage) |
| `lib/core/routing/` | go_router navigation with auth guards |
| `lib/core/theme/` | Material 3 theming with system/light/dark modes |
| `test/helpers/` | Shared fixtures, mocks (mocktail), and widget test utilities |

## Getting Started

### Prerequisites

- Flutter SDK (stable channel)
- Xcode 16+ (for iOS builds)
- A running instance of [saltybytes-api](https://github.com/windoze95/saltybytes-api)

### Setup

1. **Clone the repository**

```bash
git clone https://github.com/windoze95/saltybytes-app.git
cd saltybytes-app
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Run the app**

```bash
flutter run
```

4. **Build for release** (requires codesigning)

```bash
flutter build ipa --release \
  --dart-define=SALTYBYTES_ID=your_id_header_value \
  --export-options-plist=ios/ExportOptions.plist
```

## Testing

All tests run offline — no network, API, or simulator required.

```bash
# Run all tests
flutter test

# Verbose
flutter test --reporter expanded

# Specific file
flutter test test/providers/search_provider_test.dart

# Specific test by name
flutter test --name "displays recipe title"
```

### Test structure

```
test/
├── helpers/
│   ├── fixtures.dart       # Factory functions for JSON maps and model instances
│   ├── test_helpers.dart   # MockDio, MockSecureStorage, provider container helpers
│   └── pump_helpers.dart   # Widget test wrappers (testApp, testAppScaffold)
├── core/
│   └── utils/              # Unit converter tests
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

**Note:** Widget tests must use `tester.pump(Duration)` instead of `pumpAndSettle()` — `flutter_animate` has infinitely repeating animations that prevent `pumpAndSettle` from completing.

## Deployment

CI/CD runs via GitHub Actions on push to `main`:

- Flutter build → IPA → Fastlane → TestFlight

Apple signing credentials and API keys are injected via GitHub Secrets.

## Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Navigation**: go_router
- **HTTP**: Dio (with JWT auth interceptors and automatic token refresh)
- **Storage**: flutter_secure_storage, sqflite
- **Voice**: speech_to_text
- **Theming**: Material 3 (system/light/dark)
- **Testing**: mocktail, flutter_test
- **CI/CD**: GitHub Actions → Fastlane → TestFlight

## License

Licensed under the [Business Source License 1.1](LICENSE). You may use, modify, and contribute to this code, but you may not offer it as a competing commercial product. The license converts to Apache 2.0 on the change date specified in the LICENSE file.
