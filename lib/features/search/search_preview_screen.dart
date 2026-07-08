import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/smart_back.dart';
import '../../core/network/api_client.dart';
import '../../core/providers/recipe_provider.dart';
import '../../core/providers/search_provider.dart';

class SearchPreviewScreen extends ConsumerStatefulWidget {
  const SearchPreviewScreen({super.key, required this.searchResult});

  final WebSearchResult searchResult;

  @override
  ConsumerState<SearchPreviewScreen> createState() =>
      _SearchPreviewScreenState();
}

class _SearchPreviewScreenState extends ConsumerState<SearchPreviewScreen> {
  late Future<RecipePreview> _previewFuture;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _previewFuture = _loadPreview();
  }

  /// Load preview. If the backend detects a multi-recipe page, it throws
  /// MultiRecipeException. We replace the original card with the individual
  /// recipes and pop back with the target index so the search screen can
  /// navigate there.
  Future<RecipePreview> _loadPreview() async {
    try {
      return await ref
          .read(searchProvider.notifier)
          .previewResult(widget.searchResult);
    } on MultiRecipeException catch (e) {
      if (mounted) {
        final targetIndex = ref
            .read(searchProvider.notifier)
            .replaceWithExpanded(e.sourceResult, e.resolution);
        if (context.canPop()) {
          context.pop<int?>(targetIndex);
        } else {
          // Deep-linked collection URL: there is no search screen below to
          // receive the pop result (and pop() on a bare stack throws). The
          // provider already holds the expanded cards, so show them there.
          context.go('/search');
        }
      }
      return Future.error('multi-recipe redirect');
    }
  }

  Future<void> _importRecipe(RecipePreview preview) async {
    setState(() => _isImporting = true);
    // The container stays usable after this screen is popped (a disposed
    // widget's `ref` throws), so the list still refreshes if the user backs
    // out during a slow import.
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      final recipe = await ref.read(searchProvider.notifier).importPreview(
            preview,
            imageUrl: widget.searchResult.imageUrl,
          );
      container.invalidate(recipeListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported "${recipe.title}"!')),
        );
        // pushReplacement keeps the underlying stack (search) so the detail
        // screen still has a back route; go() would replace the whole stack
        // and strand the user.
        context.pushReplacement('/recipe/${recipe.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFacingErrorMessage(
              e,
              'Failed to import the recipe. Please try again.',
            )),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Explicit leading: opened from a shared/universal link this screen
        // is the whole stack, and the implied back button would vanish.
        leading: smartBackLeading(context),
        title: Text(
          widget.searchResult.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: FutureBuilder<RecipePreview>(
        future: _previewFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingState();
          }

          if (snapshot.hasError) {
            return _ErrorState(
              error: snapshot.error!,
              onRetry: () {
                setState(() {
                  _previewFuture = ref
                      .read(searchProvider.notifier)
                      .previewResult(widget.searchResult);
                });
              },
            );
          }

          final preview = snapshot.data!;
          return _PreviewBody(
            preview: preview,
            isImporting: _isImporting,
            onImport: () => _importRecipe(preview),
          );
        },
      ),
    );
  }
}

class _LoadingState extends StatefulWidget {
  const _LoadingState();

  @override
  State<_LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<_LoadingState> {
  // The phases the backend actually moves through for a fresh extraction:
  // fetch the page, pull out the recipe, assemble it. (A cache hit returns
  // before any of this shows; a multi-recipe page swaps to the card view as
  // soon as detection finishes.)
  static const _phases = [
    'Reading the page…',
    'Extracting the recipe…',
    'Putting it together…',
  ];

  int _phase = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (!mounted) return;
      if (_phase < _phases.length - 1) {
        setState(() => _phase++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _phases[_phase],
              key: ValueKey<int>(_phase),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few seconds',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final IconData icon;
    final String title;
    final String detail;

    if (error is PreviewException) {
      final pe = error as PreviewException;
      switch (pe.code) {
        case 'site_blocked':
          icon = Icons.block;
          title = 'Website blocked access';
          break;
        case 'not_found':
          icon = Icons.search_off;
          title = 'Page not found';
          break;
        default:
          icon = Icons.error_outline;
          title = 'Failed to load preview';
      }
      detail = pe.message;
    } else {
      icon = Icons.error_outline;
      title = 'Failed to load preview';
      detail = userFacingErrorMessage(
          error, 'Could not load the preview. Please try again.');
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 48,
                color: theme.colorScheme.error.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(detail,
                textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({
    required this.preview,
    required this.isImporting,
    required this.onImport,
  });

  final RecipePreview preview;
  final bool isImporting;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cache-hit badge — honest about an instant saved load.
                      if (preview.fromCache) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bookmark_rounded,
                                size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Loaded from your saved recipes',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Title
                      Text(
                        preview.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      // Source domain
                      if (preview.sourceDomain != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          preview.sourceDomain!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.primary,
                          ),
                        ),
                      ],

                      // Metadata chips
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (preview.cookTime != null && preview.cookTime! > 0)
                            _MetadataChip(
                              icon: Icons.timer_outlined,
                              label: '${preview.cookTime} min',
                            ),
                          if (preview.portions != null && preview.portions! > 0)
                            _MetadataChip(
                              icon: Icons.restaurant,
                              label: preview.portionSize != null &&
                                      preview.portionSize!.isNotEmpty
                                  ? '${preview.portions} ${preview.portionSize}'
                                  : '${preview.portions} servings',
                            ),
                        ],
                      ),

                      // Ingredients
                      if (preview.ingredients.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Ingredients',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...preview.ingredients.map(
                          (ing) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color:
                                        colors.primary.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    ing.displayText,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Instructions
                      if (preview.instructions.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Instructions',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (int i = 0; i < preview.instructions.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  i == preview.instructions.length - 1 ? 0 : 16,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color:
                                        colors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${i + 1}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      preview.instructions[i],
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],

                      // Hashtags
                      if (preview.hashtags.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: preview.hashtags
                              .map(
                                (tag) => Chip(
                                  label: Text(
                                    '#$tag',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                      ],

                      // Similar recipes from around the web
                      if (preview.sourceUrl != null &&
                          preview.sourceUrl!.isNotEmpty)
                        _PreviewSimilar(sourceUrl: preview.sourceUrl!),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom import bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isImporting ? null : onImport,
                icon: isImporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download, size: 18),
                label: Text(isImporting ? 'Importing...' : 'Import Recipe'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// "You might also like" — recipes from the extraction pool similar to the
/// previewed page. Quietly hides while loading, on error, or when empty, so
/// it never adds noise to a preview the user is deciding whether to import.
/// Tapping a card opens that recipe's own preview.
class _PreviewSimilar extends ConsumerWidget {
  const _PreviewSimilar({required this.sourceUrl});

  final String sourceUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final similar = ref.watch(similarByUrlProvider(sourceUrl));

    return similar.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (recipes) {
        if (recipes.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'You might also like',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recipes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _SimilarWebCard(
                  recipe: recipes[index],
                  onTap: () => context.push(
                    '/preview?u=${Uri.encodeQueryComponent(recipes[index].sourceUrl)}',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SimilarWebCard extends StatelessWidget {
  const _SimilarWebCard({required this.recipe, required this.onTap});

  final SimilarWebRecipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 168,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe.sourceDomain.isNotEmpty)
              Text(
                recipe.sourceDomain,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                recipe.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
