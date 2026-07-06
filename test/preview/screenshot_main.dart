// Dev-only STORE-SCREENSHOT harness: boots the REAL app screens (theme, shell
// navigation, Search/Home/Detail/Family/Import/Preview) with a faked signed-in
// session and a stubbed HTTP layer that returns rich demo payloads — including
// the agent-search SSE stream — so the UI renders fully populated in a browser
// with no server:
//
//   flutter build web --release -t test/preview/screenshot_main.dart -o build/web_screens
//
// Driven at exact store pixel sizes by tool/screenshots/shoot.js. Query params
// steer per-shot behavior (the runner appends them):
//   ?view=list          — switch Search to list view at boot
//   ?shot=search_live   — the /find SSE stream stalls mid-dig (working state)
//
// The router here is a slim clone of lib/core/navigation/app_router.dart: it
// mounts only the screens we screenshot, because the real router transitively
// imports cooking mode (vosk_flutter_2 -> dart:ffi) and the photo importer
// (dart:io), neither of which compiles for web. Never ship or import this
// from lib/.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/core/providers/search_provider.dart';
import 'package:saltybytes_app/core/storage/secure_storage.dart';
import 'package:saltybytes_app/core/theme/app_theme.dart';
import 'package:saltybytes_app/features/family/family_screen.dart';
import 'package:saltybytes_app/features/home/home_screen.dart';
import 'package:saltybytes_app/features/import/import_screen.dart';
import 'package:saltybytes_app/features/recipe/recipe_detail_screen.dart';
import 'package:saltybytes_app/features/search/search_preview_screen.dart';
import 'package:saltybytes_app/features/search/search_screen.dart';
import 'package:saltybytes_app/features/settings/settings_screen.dart';

import 'screenshot_data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = _FakeSecureStorage();
  final container = ProviderContainer(
    overrides: [
      secureStorageProvider.overrideWithValue(storage),
      authStateProvider.overrideWith(_FakeAuthNotifier.new),
      apiClientProvider.overrideWithValue(_stubApiClient(storage)),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const _ScreenshotApp(),
    ),
  );

  // Per-shot boot config, applied once the first frame exists.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (Uri.base.queryParameters['view'] == 'list') {
      container
          .read(searchProvider.notifier)
          .setViewMode(SearchViewMode.list);
    }
  });
}

class _ScreenshotApp extends StatelessWidget {
  const _ScreenshotApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SaltyBytes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }
}

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Signed-in immediately; no storage, no /users/me gate.
class _FakeAuthNotifier extends AsyncNotifier<AuthStatus>
    implements AuthNotifier {
  @override
  bool needsEmailVerification = false;

  @override
  void markEmailVerificationHandled() {}

  @override
  Future<AuthStatus> build() async => AuthStatus.authenticated;

  @override
  Future<void> login({required String username, required String password}) async {}

  @override
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> logout() async {}
}

/// In-memory SecureStorage so the harness never touches platform keychains.
class _FakeSecureStorage implements SecureStorage {
  final Map<String, String> _values = {};

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}

  @override
  Future<String?> getAccessToken() async => 'screenshot-token';

  @override
  Future<String?> getRefreshToken() async => 'screenshot-refresh';

  @override
  Future<void> clearTokens() async {}

  @override
  Future<bool> hasTokens() async => true;

  @override
  Future<void> saveUserId(String userId) async {}

  @override
  Future<String?> getUserId() async => 'user-demo-1';

  @override
  Future<void> savePreference(String key, String value) async {
    _values['pref_$key'] = value;
  }

  @override
  Future<String?> getPreference(String key) async => _values['pref_$key'];

  @override
  Future<void> saveThemeMode(String mode) async {}

  @override
  Future<String?> getThemeMode() async => 'light';

  @override
  Future<void> setOnboardingComplete() async {}

  @override
  Future<bool> isOnboardingComplete() async => true;

  @override
  Future<void> clearAll() async {}
}

ApiClient _stubApiClient(SecureStorage storage) {
  final client = ApiClient(secureStorage: storage);
  client.dio.httpClientAdapter = _ScreenshotAdapter();
  return client;
}

// ---------------------------------------------------------------------------
// Stubbed backend
// ---------------------------------------------------------------------------

class _ScreenshotAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;

    // The agent run: an SSE stream of finder events.
    if (path == '/v1/recipes/find') {
      final stall = Uri.base.queryParameters['shot'] == 'search_live';
      return ResponseBody(
        _sseStream(stall: stall),
        200,
        headers: {
          Headers.contentTypeHeader: ['text/event-stream'],
        },
      );
    }

    return _json(_bodyFor(path, options));
  }

  Object _bodyFor(String path, RequestOptions options) {
    // Ordered by specificity.
    if (path == '/v1/users/me') return {'user': demoUser()};
    if (path == '/v1/users/me/settings') {
      return {'settings': demoUser()['settings']};
    }
    if (path == '/v1/family') return {'family': demoFamily()};
    if (path == '/v1/subscription') {
      return {'subscription': testSubscriptionJsonForShots()};
    }
    if (path == '/v1/recipes/search/warm') {
      final urls =
          ((options.data as Map?)?['urls'] as List?)?.cast<String>() ?? [];
      return {
        'statuses': {for (final u in urls) u: 'cached'},
      };
    }
    if (path == '/v1/recipes/preview/url') {
      return {'recipe': demoPreview(), 'from_cache': false};
    }
    if (path.startsWith('/v1/recipes/similar/')) {
      return {'similar_recipes': demoSimilarRecipes()};
    }
    if (path.startsWith('/v1/recipes/finder/sessions')) {
      return {'sessions': const []};
    }
    if (RegExp(r'^/v1/recipes/[^/]+/allergens$').hasMatch(path)) {
      return {'analysis': demoAllergenAnalysis()};
    }
    if (path == '/v1/recipes/search') {
      return {
        'results': [
          for (final item in demoShortlist())
            (item['result'] as Map<String, dynamic>),
        ],
        'has_more': false,
      };
    }
    if (path == '/v1/recipes') return {'recipes': demoSavedRecipes()};
    final recipeMatch = RegExp(r'^/v1/recipes/([^/]+)$').firstMatch(path);
    if (recipeMatch != null) {
      final id = recipeMatch.group(1);
      final saved = demoSavedRecipes();
      return {
        'recipe': saved.firstWhere(
          (r) => r['id'] == id,
          orElse: demoDetailRecipe,
        ),
      };
    }

    // Shape-aware empty defaults so unmocked screens settle instead of crash.
    if (path.contains('/allergens')) return {'analysis': null};
    return const <String, dynamic>{};
  }

  /// The finder run as SSE frames. [stall] leaves the stream open mid-dig so
  /// the UI holds its live "agent working" state for the screenshot.
  Stream<Uint8List> _sseStream({required bool stall}) async* {
    Uint8List frame(Map<String, dynamic> event) =>
        Uint8List.fromList(utf8.encode('data: ${jsonEncode(event)}\n\n'));

    Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 120));

    yield frame({'type': 'searching', 'query': 'cozy comfort food'});
    await tick();
    yield frame({'type': 'found', 'count': 24, 'from_cache': false});
    await tick();
    yield frame({
      'type': 'results',
      'items': demoInstantResults(),
      'has_more': false,
    });
    await tick();
    yield frame({'type': 'filtering'});
    await tick();
    yield frame({
      'type': 'shortlist',
      'items': demoShortlist(),
      'has_more': false,
    });
    await tick();
    yield frame({'type': 'digging', 'collection_title': demoCollectionTitle});
    await tick();

    if (stall) {
      // Hold the run open: narration spinner + digging chip stay live.
      await Completer<void>().future;
      return;
    }

    yield frame({
      'type': 'expanded',
      'collection_title': demoCollectionTitle,
      'items': demoExpanded(),
    });
    await tick();
    yield frame({'type': 'picks', 'items': demoPicks()});
    await tick();
    yield frame({'type': 'warming'});
    await tick();
    yield frame({
      'type': 'refine_ready',
      'chips': demoRefineChips(),
      'broaden': const <String>[],
    });
    await tick();
    yield frame({'type': 'done'});
  }

  ResponseBody _json(Object body) => ResponseBody.fromString(
        jsonEncode(body),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

/// Free tier with believable usage for any settings-adjacent fetches.
Map<String, dynamic> testSubscriptionJsonForShots() => {
      'ID': 1,
      'CreatedAt': '2026-01-01T00:00:00Z',
      'UpdatedAt': '2026-06-01T00:00:00Z',
      'DeletedAt': null,
      'UserID': 1,
      'Tier': 'premium',
      'ExpiresAt': null,
      'AllergenAnalysesUsed': 4,
      'WebSearchesUsed': 11,
      'AIGenerationsUsed': 6,
      'MonthlyResetAt': '2026-08-01T00:00:00Z',
    };

// ---------------------------------------------------------------------------
// Slim router (clone of the real shell + the screenshot routes only)
// ---------------------------------------------------------------------------

final _router = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => _ScaffoldWithNavBar(child: child),
      routes: [
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/search',
          name: 'search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/family',
          name: 'family',
          builder: (context, state) => const FamilyScreen(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/search/preview',
      name: 'search-preview',
      builder: (context, state) {
        final result = state.extra as WebSearchResult? ??
            WebSearchResult.fromJson(demoPreviewSourceResult());
        return SearchPreviewScreen(searchResult: result);
      },
    ),
    // The real router pushes these by name from the screens we mount; give the
    // names a home so stray taps during a shot can't crash the harness.
    GoRoute(
      path: '/search/history',
      name: 'search-history',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/recipe/:id',
      name: 'recipe-detail',
      builder: (context, state) =>
          RecipeDetailScreen(recipeId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/import',
      name: 'import',
      builder: (context, state) => const ImportScreen(),
    ),
  ],
);

/// Verbatim clone of the app shell's bottom navigation (private in
/// lib/core/navigation/app_router.dart).
class _ScaffoldWithNavBar extends StatelessWidget {
  const _ScaffoldWithNavBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Family',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/family')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.goNamed('home');
      case 1:
        context.goNamed('search');
      case 2:
        context.goNamed('family');
      case 3:
        context.goNamed('settings');
    }
  }
}
