import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/allergen_provider.dart';
import '../../core/providers/recipe_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/recipe.dart';
import 'widgets/allergen_badge.dart';
import 'widgets/ingredient_list.dart';
import 'widgets/instruction_list.dart';

class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(recipeDetailProvider(recipeId));

    return recipeAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: _ErrorBody(
          error: error.toString(),
          onRetry: () => ref.invalidate(recipeDetailProvider(recipeId)),
        ),
      ),
      data: (recipe) => _RecipeDetailBody(recipe: recipe),
    );
  }
}

class _RecipeDetailBody extends ConsumerWidget {
  const _RecipeDetailBody({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final allergenAsync = ref.watch(allergenAnalysisProvider(recipe.id));

    final hasAllergenWarning = allergenAsync.whenOrNull(
      data: (analysis) => !analysis.isSafeForAll,
    ) ?? false;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero image app bar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: recipe.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: recipe.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: colors.primary.withValues(alpha: 0.1),
                        child: Center(
                          child: Icon(
                            Icons.restaurant,
                            size: 64,
                            color: colors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: colors.primary.withValues(alpha: 0.1),
                        child: Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 64,
                            color: colors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: colors.primary.withValues(alpha: 0.1),
                      child: Center(
                        child: Icon(
                          Icons.restaurant_menu,
                          size: 80,
                          color: colors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {},
              ),
            ],
          ),

          // Allergen warning banner
          if (hasAllergenWarning)
            SliverToBoxAdapter(
              child: Material(
                color: colors.error.withValues(alpha: 0.1),
                child: InkWell(
                  onTap: () => context.pushNamed(
                    'recipe-allergens',
                    pathParameters: {'id': recipe.id},
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: colors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Contains allergens unsafe for family members',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: colors.error,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Title
                Text(
                  recipe.title,
                  style: theme.textTheme.recipeTitle,
                ),
                const SizedBox(height: 12),

                // Metadata chips
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (recipe.cookTimeMinutes != null)
                      _MetadataChip(
                        icon: Icons.timer_outlined,
                        label: '${recipe.cookTimeMinutes} min',
                      ),
                    if (recipe.prepTimeMinutes != null)
                      _MetadataChip(
                        icon: Icons.hourglass_bottom,
                        label: '${recipe.prepTimeMinutes} min prep',
                      ),
                    _MetadataChip(
                      icon: Icons.restaurant_outlined,
                      label: '${recipe.servings} servings',
                    ),
                    if (recipe.difficulty != null)
                      _MetadataChip(
                        icon: Icons.signal_cellular_alt,
                        label: recipe.difficulty!,
                      ),
                    if (recipe.cuisine != null)
                      _MetadataChip(
                        icon: Icons.public,
                        label: recipe.cuisine!,
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Allergen badges
                if (recipe.allergenTags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: recipe.allergenTags
                        .map((tag) => AllergenBadge(
                              label: tag,
                              severity: AllergenSeverity.unsafe,
                            ))
                        .toList(),
                  ),
                ],

                const SizedBox(height: 8),
                if (recipe.description != null) ...[
                  Text(
                    recipe.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                const Divider(height: 32),

                // Ingredients
                Text(
                  'Ingredients',
                  style: theme.textTheme.recipeSectionHeader,
                ),
                const SizedBox(height: 12),
                IngredientList(
                  ingredients: recipe.ingredients,
                  servings: recipe.servings,
                ),

                const Divider(height: 32),

                // Instructions
                Text(
                  'Instructions',
                  style: theme.textTheme.recipeSectionHeader,
                ),
                const SizedBox(height: 12),
                InstructionList(instructions: recipe.instructions),

                // Tags
                if (recipe.tags.isNotEmpty) ...[
                  const Divider(height: 32),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recipe.tags
                        .map((tag) => Chip(
                              label: Text('#$tag'),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
                ],

                // Branch info
                if (recipe.currentBranch != 'main') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_tree_outlined,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Branch: ${recipe.currentBranch}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (recipe.version != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            'v${recipe.version}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.primary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Similar recipes
                const Divider(height: 32),
                _SimilarRecipes(recipeId: recipe.id),

                // Bottom padding for action bar
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ActionBar(recipe: recipe),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.pushNamed(
                    'cooking-mode',
                    pathParameters: {'id': recipe.id},
                  ),
                  icon: const Icon(Icons.local_fire_department, size: 20),
                  label: const Text('Cook'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: () => context.pushNamed(
                  'recipe-edit',
                  pathParameters: {'id': recipe.id},
                ),
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit',
              ),
              const SizedBox(width: 4),
              IconButton.outlined(
                onPressed: () => context.pushNamed(
                  'recipe-fork',
                  pathParameters: {'id': recipe.id},
                ),
                icon: const Icon(Icons.fork_right, size: 20),
                tooltip: 'Fork',
              ),
              const SizedBox(width: 4),
              IconButton.outlined(
                onPressed: () => context.pushNamed(
                  'recipe-branches',
                  pathParameters: {'id': recipe.id},
                ),
                icon: const Icon(Icons.account_tree_outlined, size: 20),
                tooltip: 'Branches',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimilarRecipes extends ConsumerWidget {
  const _SimilarRecipes({required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final similarAsync = ref.watch(similarRecipesProvider(recipeId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Similar Recipes',
          style: theme.textTheme.recipeSectionHeader,
        ),
        const SizedBox(height: 12),
        similarAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Could not load similar recipes.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          data: (recipes) {
            if (recipes.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No similar recipes found yet.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              );
            }
            return SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recipes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return _SimilarRecipeCard(
                    recipe: recipe,
                    onTap: () => context.pushNamed(
                      'recipe-detail',
                      pathParameters: {'id': recipe.id},
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SimilarRecipeCard extends StatelessWidget {
  const _SimilarRecipeCard({
    required this.recipe,
    required this.onTap,
  });

  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SizedBox(
      width: 140,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: recipe.imageUrl != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: recipe.imageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Center(
                              child: Icon(
                                Icons.restaurant,
                                color: colors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.restaurant,
                            color: colors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  recipe.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load recipe',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
