import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/search_provider.dart';
import 'widgets/search_result_card.dart';

enum _ViewMode { fullScreen, grid }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  PageController _pageController = PageController();
  final _gridScrollController = ScrollController();
  _ViewMode _viewMode = _ViewMode.fullScreen;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _gridScrollController.addListener(_onGridScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    _gridScrollController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _currentPage = 0;
      _pageController.dispose();
      _pageController = PageController();
      ref.read(searchProvider.notifier).search(query);
    }
  }

  void _onPageChanged(int index) {
    _currentPage = index;
    final searchState = ref.read(searchProvider);
    // Warm the cache a few cards ahead of where the user is.
    ref.read(searchProvider.notifier).warmAhead(index);
    final threshold = searchState.results.length - 3;
    if (index >= threshold && searchState.hasMore && !searchState.isLoadingMore) {
      ref.read(searchProvider.notifier).loadMore();
    }
  }

  void _onGridScroll() {
    final pos = _gridScrollController.position;
    final searchState = ref.read(searchProvider);
    // Estimate the top-of-fold index from the scroll fraction and warm ahead.
    if (pos.maxScrollExtent > 0 && searchState.results.isNotEmpty) {
      final frac = (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0);
      final visibleIndex = (frac * searchState.results.length).floor();
      ref.read(searchProvider.notifier).warmAhead(visibleIndex);
    }
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      if (searchState.hasMore && !searchState.isLoadingMore) {
        ref.read(searchProvider.notifier).loadMore();
      }
    }
  }

  void _switchToFullScreen(int index) {
    _pageController.dispose();
    _pageController = PageController(initialPage: index);
    _currentPage = index;
    setState(() => _viewMode = _ViewMode.fullScreen);
  }

  Future<void> _previewResult(WebSearchResult result) async {
    final popResult =
        await context.push<int?>('/search/preview', extra: result);
    if (popResult != null && mounted && _viewMode == _ViewMode.fullScreen) {
      // Multi-recipe expansion returned a target index
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(popResult);
        }
      });
    }
  }

  void _toggleViewMode() {
    setState(() {
      if (_viewMode == _ViewMode.fullScreen) {
        _viewMode = _ViewMode.grid;
      } else {
        _switchToFullScreen(_currentPage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Recipes'),
        actions: [
          if (searchState.results.isNotEmpty)
            IconButton(
              icon: Icon(
                _viewMode == _ViewMode.fullScreen
                    ? Icons.grid_view_rounded
                    : Icons.view_agenda_rounded,
              ),
              tooltip: _viewMode == _ViewMode.fullScreen
                  ? 'Grid view'
                  : 'Full screen view',
              onPressed: _toggleViewMode,
            ),
        ],
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
              Icon(Icons.error_outline,
                  size: 48,
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
      return const _EmptySearchState();
    }

    if (searchState.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off,
                  size: 64,
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

    if (_viewMode == _ViewMode.fullScreen) {
      return _buildFullScreenView(searchState);
    } else {
      return _buildGridView(theme, searchState);
    }
  }

  Widget _buildFullScreenView(SearchState searchState) {
    final itemCount =
        searchState.results.length + (searchState.hasMore ? 1 : 0);

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: itemCount,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        if (index >= searchState.results.length) {
          return const _FullScreenLoadingPage();
        }
        final result = searchState.results[index];
        return _FullScreenResultPage(
          result: result,
          onTap: () => _previewResult(result),
        );
      },
    );
  }

  Widget _buildGridView(ThemeData theme, SearchState searchState) {
    // If the grid can't scroll but more results exist, trigger pagination.
    if (searchState.hasMore && !searchState.isLoadingMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_gridScrollController.hasClients) return;
        final pos = _gridScrollController.position;
        if (pos.maxScrollExtent <= 0) {
          ref.read(searchProvider.notifier).loadMore();
        }
      });
    }

    final itemCount =
        searchState.results.length + (searchState.isLoadingMore ? 1 : 0);

    return GridView.builder(
      controller: _gridScrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= searchState.results.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final result = searchState.results[index];
        return SearchResultCard(
          result: result,
          onTap: () => _switchToFullScreen(index),
          index: index,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Full-screen page for a single search result
// ---------------------------------------------------------------------------

class _FullScreenResultPage extends StatelessWidget {
  const _FullScreenResultPage({
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Hero image
          if (result.imageUrl != null)
            CachedNetworkImage(
              imageUrl: result.imageUrl!,
              // Cap the decoded bitmap so large source photos don't blow up
              // memory (iOS jetsam) — full-screen hero, decode near screen width.
              memCacheWidth: 1080,
              fit: BoxFit.cover,
              placeholder: (_, __) => _FullScreenPlaceholder(theme: theme),
              errorWidget: (_, __, ___) =>
                  _FullScreenPlaceholder(theme: theme),
            )
          else
            _FullScreenPlaceholder(theme: theme),

          // Bottom gradient overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xCC000000),
                  ],
                ),
              ),
            ),
          ),

          // Metadata overlay
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Extraction status for a multi-recipe card still resolving
                  if (isPendingExtraction(result.extractionStatus) ||
                      result.extractionStatus == 'failed') ...[
                    ExtractionStatusBadge(status: result.extractionStatus!),
                    const SizedBox(height: 10),
                  ],
                  // Rating
                  if (result.rating != null) ...[
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          final filled = i < result.rating!.round();
                          return Icon(
                            filled ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 18,
                            color: filled
                                ? const Color(0xFFF9A825)
                                : Colors.white38,
                          );
                        }),
                        const SizedBox(width: 6),
                        Text(
                          result.rating!.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Title
                  Text(
                    result.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Source domain + cook time
                  Row(
                    children: [
                      if (result.sourceDomain != null)
                        Flexible(
                          child: Text(
                            result.sourceDomain!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      if (result.sourceDomain != null &&
                          result.cookTimeMinutes != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Colors.white38,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      if (result.cookTimeMinutes != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 16, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              '${result.cookTimeMinutes} min',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  // Description
                  if (result.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      result.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                  ],

                  // Family safety badges
                  if (result.familySafetyChecks.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: result.familySafetyChecks
                          .map((check) => SafetyBadge(check: check))
                          .toList(),
                    ),
                  ],

                  // Preview button
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Preview Recipe'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenPlaceholder extends StatelessWidget {
  const _FullScreenPlaceholder({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.15),
            theme.colorScheme.secondary.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant,
          size: 64,
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}

class _FullScreenLoadingPage extends StatelessWidget {
  const _FullScreenLoadingPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(height: 16),
          Text('Finding more recipes...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              )),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 0.5, end: 1.0, duration: 800.ms);
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

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
