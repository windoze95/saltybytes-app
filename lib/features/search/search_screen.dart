import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/search_provider.dart';
import '../../models/allergen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _swiperController = SwiperController();
  int _currentIndex = 0;
  bool _isPopping = false;
  ({int start, int end})? _expandedRange;

  @override
  void dispose() {
    _searchController.dispose();
    _swiperController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() => _currentIndex = 0);
      ref.read(searchProvider.notifier).search(query);
    }
  }

  void _previewResult(WebSearchResult result) {
    context.push('/search/preview', extra: result);
  }

  void _onExpansionPhaseChange(SearchState? prev, SearchState next) {
    if (prev?.expansionPhase == null &&
        next.expansionPhase == ExpansionPhase.inserted) {
      // Record the range of newly inserted cards (right after the original).
      final origIdx = next.results
          .indexWhere((r) => r.sourceUrl == next.pendingPopUrl);
      if (origIdx >= 0) {
        final count = next.expandedCardCount;
        _expandedRange = (start: origIdx + 1, end: origIdx + count);
      }
      // Brief pause, then trigger the pop animation.
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        ref.read(searchProvider.notifier).beginPop();
        setState(() => _isPopping = true);
      });
    }
  }

  void _onPopComplete() {
    if (!mounted) return;
    ref.read(searchProvider.notifier).completePop();
    setState(() => _isPopping = false);
    // After removal, adjust the expanded range (shifted down by 1).
    if (_expandedRange != null) {
      _expandedRange = (
        start: _expandedRange!.start - 1,
        end: _expandedRange!.end - 1,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _swiperController.move(_currentIndex, animation: false);
      }
    });
  }

  void _onIndexChanged(int index) {
    _currentIndex = index;
    if (_expandedRange != null && index > _expandedRange!.end) {
      ref.read(searchProvider.notifier).clearGlow();
      _expandedRange = null;
    }

    // Prefetch more results when approaching the end of the deck.
    final searchState = ref.read(searchProvider);
    final threshold = searchState.results.length - 3;
    if (index >= threshold &&
        searchState.hasMore &&
        !searchState.isLoadingMore) {
      ref.read(searchProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchProvider);

    ref.listen<SearchState>(searchProvider, _onExpansionPhaseChange);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Recipes'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for recipes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _performSearch,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _performSearch(),
            ),
          ),

          // Results area
          Expanded(
            child: _buildBody(theme, searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme, SearchState searchState) {
    if (searchState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48,
                  color: theme.colorScheme.error.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text('Search failed', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(searchState.error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              OutlinedButton(
                  onPressed: _performSearch, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (!searchState.hasSearched) {
      return _EmptySearchState();
    }

    if (searchState.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 64,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text('No results found', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Try different keywords or check your spelling.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    // Card stack
    final itemCount =
        searchState.results.length + (searchState.hasMore ? 1 : 0);

    return Swiper(
      controller: _swiperController,
      index: _currentIndex,
      onIndexChanged: _onIndexChanged,
      itemCount: itemCount,
      loop: false,
      itemBuilder: (context, index) {
        // Loading placeholder at the end of the deck
        if (index >= searchState.results.length) {
          return _LoadingPlaceholderCard();
        }

        final result = searchState.results[index];
        final isPopping =
            _isPopping && result.sourceUrl == searchState.pendingPopUrl;
        final isGlowing =
            searchState.expandedCardUrls.contains(result.sourceUrl);

        Widget card = _SearchResultCard(
          key: ValueKey(result.sourceUrl ?? index),
          result: result,
          onTap: () => _previewResult(result),
        );

        if (isPopping) {
          card = card
              .animate(onComplete: (_) => _onPopComplete())
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(0.85, 0.85),
                duration: 250.ms,
                curve: Curves.easeIn,
              )
              .fadeOut(duration: 250.ms, curve: Curves.easeIn);
        } else if (isGlowing) {
          card = card
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .custom(
                duration: 1200.ms,
                curve: Curves.easeInOut,
                builder: (context, value, child) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.tertiary
                            .withValues(alpha: 0.4 * value),
                        blurRadius: 16 * value,
                        spreadRadius: 2 * value,
                      ),
                    ],
                  ),
                  child: child,
                ),
              );
        }

        return card;
      },
      layout: SwiperLayout.STACK,
      itemWidth: MediaQuery.of(context).size.width * 0.85,
      itemHeight: MediaQuery.of(context).size.height * 0.55,
    );
  }
}

class _LoadingPlaceholderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: 16),
            Text('Finding more recipes...',
                style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 0.5, end: 1.0, duration: 800.ms);
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    super.key,
    required this.result,
    required this.onTap,
  });

  final WebSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
              ),
              child: result.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: result.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Center(
                        child: Icon(Icons.restaurant, size: 40,
                            color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      errorWidget: (_, __, ___) => Center(
                        child: Icon(Icons.broken_image_outlined, size: 40,
                            color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                    )
                  : Center(
                      child: Icon(Icons.restaurant, size: 48,
                          color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                    ),
            ),
          ),

          // Info
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (result.sourceDomain != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      result.sourceDomain!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],

                  // Rating
                  if (result.rating != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          final filled = i < result.rating!.round();
                          return Icon(
                            filled ? Icons.star : Icons.star_border,
                            size: 18,
                            color: filled
                                ? const Color(0xFFF9A825)
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                          );
                        }),
                        const SizedBox(width: 6),
                        Text(
                          result.rating!.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],

                  if (result.description != null) ...[
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        result.description!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],

                  // Family safety checks
                  if (result.familySafetyChecks.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: result.familySafetyChecks
                          .map((check) => _SafetyBadge(check: check))
                          .toList(),
                    ),
                  ],

                  const Spacer(),

                  // Preview button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Preview Recipe'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _SafetyBadge extends StatelessWidget {
  const _SafetyBadge({required this.check});

  final FamilySafetyCheck check;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = check.isSafe ? theme.colorScheme.tertiary : theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            check.isSafe ? Icons.check_circle : Icons.warning,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            check.memberName,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
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
              Icons.travel_explore,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Search for recipes across the web',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Find recipes from thousands of websites, '
              'personalized for your family\'s dietary needs.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
