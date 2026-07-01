import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/cooking/cooking_mode_screen.dart';
import '../../features/family/dietary_interview_screen.dart';
import '../../features/family/family_member_detail_screen.dart';
import '../../features/family/family_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/import/import_manual_screen.dart';
import '../../features/import/import_photo_screen.dart';
import '../../features/import/import_screen.dart';
import '../../features/import/import_text_screen.dart';
import '../../features/import/import_url_screen.dart';
import '../../features/import/import_video_screen.dart';
import '../../features/recipe/allergen_detail_screen.dart';
import '../../features/recipe/recipe_branches_screen.dart';
import '../../features/recipe/recipe_detail_screen.dart';
import '../../features/recipe/recipe_edit_screen.dart';
import '../../features/recipe/recipe_fork_screen.dart';
import '../../features/search/history_screen.dart';
import '../../features/search/search_preview_screen.dart';
import '../../features/search/search_screen.dart';
import '../providers/search_provider.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/subscription_screen.dart';
import '../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.value == AuthStatus.authenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isAuthenticated && !isAuthRoute) {
        return '/auth/login';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Shell route for bottom navigation
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

      // Search preview route (outside shell for full-screen)
      GoRoute(
        path: '/search/preview',
        name: 'search-preview',
        builder: (context, state) {
          final searchResult = state.extra as WebSearchResult;
          return SearchPreviewScreen(searchResult: searchResult);
        },
      ),

      // Agent search history (outside shell for full-screen)
      GoRoute(
        path: '/search/history',
        name: 'search-history',
        builder: (context, state) => const HistoryScreen(),
      ),

      // Recipe detail routes (outside shell for full-screen)
      GoRoute(
        path: '/recipe/:id',
        name: 'recipe-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RecipeDetailScreen(recipeId: id);
        },
        routes: [
          GoRoute(
            path: 'edit',
            name: 'recipe-edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return RecipeEditScreen(recipeId: id);
            },
          ),
          GoRoute(
            path: 'fork',
            name: 'recipe-fork',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return RecipeForkScreen(recipeId: id);
            },
          ),
          GoRoute(
            path: 'cook',
            name: 'cooking-mode',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CookingModeScreen(recipeId: id);
            },
          ),
          GoRoute(
            path: 'branches',
            name: 'recipe-branches',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return RecipeBranchesScreen(recipeId: id);
            },
          ),
          GoRoute(
            path: 'allergens',
            name: 'recipe-allergens',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AllergenDetailScreen(recipeId: id);
            },
          ),
        ],
      ),

      // Import routes
      GoRoute(
        path: '/import',
        name: 'import',
        builder: (context, state) => const ImportScreen(),
        routes: [
          GoRoute(
            path: 'url',
            name: 'import-url',
            builder: (context, state) => const ImportUrlScreen(),
          ),
          GoRoute(
            path: 'photo',
            name: 'import-photo',
            builder: (context, state) => const ImportPhotoScreen(),
          ),
          GoRoute(
            path: 'video',
            name: 'import-video',
            builder: (context, state) => const ImportVideoScreen(),
          ),
          GoRoute(
            path: 'text',
            name: 'import-text',
            builder: (context, state) => const ImportTextScreen(),
          ),
          GoRoute(
            path: 'manual',
            name: 'import-manual',
            builder: (context, state) => const ImportManualScreen(),
          ),
        ],
      ),

      // Family member detail (outside shell for full-screen)
      GoRoute(
        path: '/family/:memberId',
        name: 'family-member-detail',
        builder: (context, state) {
          final memberId = state.pathParameters['memberId']!;
          return FamilyMemberDetailScreen(memberId: memberId);
        },
        routes: [
          GoRoute(
            path: 'interview',
            name: 'dietary-interview',
            builder: (context, state) {
              final memberId = state.pathParameters['memberId']!;
              return DietaryInterviewScreen(memberId: memberId);
            },
          ),
        ],
      ),

      // Subscription (outside shell for full-screen)
      GoRoute(
        path: '/settings/subscription',
        name: 'subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
    ],
  );
});

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
