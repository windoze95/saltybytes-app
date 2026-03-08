import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    _previewFuture =
        ref.read(searchProvider.notifier).previewResult(widget.searchResult);
  }

  Future<void> _importRecipe(RecipePreview preview) async {
    setState(() => _isImporting = true);
    try {
      final recipe =
          await ref.read(searchProvider.notifier).importPreview(preview);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported "${recipe.title}"!')),
        );
        context.go('/recipe/${recipe.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Extracting recipe...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
      detail = error.toString();
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
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall),
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
                                    color: colors.primary
                                        .withValues(alpha: 0.6),
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
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
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
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
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
