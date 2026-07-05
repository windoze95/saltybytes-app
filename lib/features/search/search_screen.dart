import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/family_provider.dart';
import '../../core/providers/finder_provider.dart';
import '../../core/providers/search_provider.dart';
import '../../core/voice/speech_service.dart';
import 'widgets/agent_controls.dart';
import 'widgets/finder_shortlist_card.dart';
import 'widgets/result_badges.dart';
import 'widgets/search_run_widgets.dart';

/// One unified, search-bar-first Search surface. The bar always leads; the
/// facet pills live one tap away in a "Filters" expander. An "agent" toggle
/// switches what powers the SAME layout:
/// - Agent ON (default): SSE `/recipes/find` — real results paint instantly,
///   then the agent enhances them live (reasons, family-safety, digging
///   roundups into individual recipes, a final ★ Top Picks curation).
/// - Agent OFF: plain `GET /recipes/search` (paginated, no enhancement).
/// Two shared view modes (immersive full-screen PageView + curated list).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _ingredientController = TextEditingController();
  PageController _pageController = PageController();
  final _listScrollController = ScrollController();
  int _currentPage = 0;

  // Local UI state.
  bool _isListening = false;
  bool _filtersExpanded = false;

  @override
  void initState() {
    super.initState();
    _listScrollController.addListener(_onListScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ingredientController.dispose();
    _pageController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  SearchNotifier get _notifier => ref.read(searchProvider.notifier);

  // ---- Actions -----------------------------------------------------------

  void _runSearch() {
    FocusScope.of(context).unfocus();
    _notifier.setQuery(_searchController.text.trim());
    _resetPager();
    setState(() => _filtersExpanded = false);
    _notifier.search();
  }

  /// Fills the bar with a suggestion (or a surprise) and runs immediately —
  /// tap-first without the wall of pills.
  void _runSuggestion(String text, {bool surprise = false}) {
    _searchController.text = text;
    if (surprise) {
      _notifier.setFacets(ref
          .read(searchProvider)
          .facets
          .copyWith(surpriseMe: true));
    }
    _runSearch();
  }

  void _refine(String constraint) {
    _resetPager();
    _notifier.refine(constraint);
  }

  void _resetPager() {
    _currentPage = 0;
    _pageController.dispose();
    _pageController = PageController();
  }

  void _toggleAgent(bool value) {
    _notifier.setAgentMode(value);
    setState(() => _filtersExpanded = false);
  }

  /// Jumps from the immersive feed to the list view (where the ★ Top Picks
  /// section lives), scrolled to the top.
  void _showTopPicks() {
    _notifier.setViewMode(SearchViewMode.list);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listScrollController.hasClients) {
        _listScrollController.jumpTo(0);
      }
    });
  }

  void _toggleViewMode() {
    final mode = ref.read(searchProvider).viewMode;
    final next = mode == SearchViewMode.list
        ? SearchViewMode.immersive
        : SearchViewMode.list;
    if (next == SearchViewMode.immersive) {
      _pageController.dispose();
      _pageController = PageController(initialPage: _currentPage);
    }
    _notifier.setViewMode(next);
  }

  void _updateFacets(FinderFacets facets) => _notifier.setFacets(facets);

  void _addIngredient(FinderFacets facets) {
    final text = _ingredientController.text.trim();
    if (text.isEmpty) return;
    if (!facets.useWhatIHave.contains(text)) {
      _updateFacets(facets.copyWith(useWhatIHave: [...facets.useWhatIHave, text]));
    }
    _ingredientController.clear();
  }

  Future<void> _toggleVoice() async {
    final speech = ref.read(speechServiceProvider);
    if (_isListening) {
      await speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }
    final available = await speech.initialize(
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && mounted) {
          setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Voice input is unavailable on this device.')),
        );
      }
      return;
    }
    if (mounted) setState(() => _isListening = true);
    await speech.listen(
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() {
          _searchController.text = text;
          _searchController.selection =
              TextSelection.collapsed(offset: text.length);
          if (isFinal) _isListening = false;
        });
        _notifier.setQuery(text);
      },
    );
  }

  Future<void> _previewResult(WebSearchResult result) async {
    final popResult =
        await context.push<int?>('/search/preview', extra: result);
    final immersive = ref.read(searchProvider).viewMode == SearchViewMode.immersive;
    if (popResult != null && mounted && immersive) {
      // Multi-recipe expansion returned a target index.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) _pageController.jumpToPage(popResult);
      });
    }
  }

  // ---- Pagination / warming triggers -------------------------------------

  void _onPageChanged(int index) {
    _currentPage = index;
    final state = ref.read(searchProvider);
    _notifier.warmAhead(index);
    final threshold = state.results.length - 3;
    if (index >= threshold && state.hasMore && !state.isLoadingMore) {
      _notifier.loadMore();
    }
  }

  void _onListScroll() {
    final pos = _listScrollController.position;
    final state = ref.read(searchProvider);
    if (pos.maxScrollExtent > 0 && state.results.isNotEmpty) {
      final frac = (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0);
      _notifier.warmAhead((frac * state.results.length).floor());
    }
    if (pos.pixels >= pos.maxScrollExtent - 200 &&
        state.hasMore &&
        !state.isLoadingMore) {
      _notifier.loadMore();
    }
  }

  // ---- Build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final showRefineBar = state.agentMode &&
        state.refineChips.isNotEmpty &&
        state.results.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(state.agentMode ? 'Find a recipe' : 'Search Recipes'),
        actions: [
          IconButton(
            tooltip: 'Search history',
            icon: const Icon(Icons.history),
            onPressed: () => context.pushNamed('search-history'),
          ),
          if (state.results.isNotEmpty)
            IconButton(
              tooltip: state.viewMode == SearchViewMode.list
                  ? 'Immersive view'
                  : 'List view',
              icon: Icon(state.viewMode == SearchViewMode.list
                  ? Icons.view_day_outlined
                  : Icons.view_agenda_outlined),
              onPressed: _toggleViewMode,
            ),
          _AgentToggle(value: state.agentMode, onChanged: _toggleAgent),
          const SizedBox(width: 4),
        ],
      ),
      body: _unifiedLayout(state),
      bottomNavigationBar: showRefineBar
          ? RefineBar(
              chips: state.refineChips,
              isListening: _isListening,
              onChip: _refine,
              onVoice: _toggleVoice,
            )
          : null,
    );
  }

  // ---- Unified search-bar-first layout (both modes) -----------------------

  Widget _unifiedLayout(SearchState state) {
    final theme = Theme.of(context);
    final facets = state.facets;
    final showNarration = state.agentMode &&
        state.narration.isNotEmpty &&
        (state.isAgentActive || state.phase == FinderPhase.empty);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: state.agentMode
                  ? 'What are you in the mood for?'
                  : 'Search for recipes...',
              prefixIcon: Icon(
                  state.agentMode ? Icons.auto_awesome : Icons.search,
                  size: 20),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Voice search',
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none,
                        size: 20),
                    onPressed: _toggleVoice,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _runSearch,
                  ),
                ],
              ),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _runSearch(),
          ),
        ),
        Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: const ValueKey('filters-expander'),
            initiallyExpanded: _filtersExpanded,
            onExpansionChanged: (v) => _filtersExpanded = v,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            leading: const Icon(Icons.tune, size: 20),
            title: Text('Filters (${facets.selectedCount})',
                style: theme.textTheme.bodyMedium),
            children: [
              // Bounded + scrollable so a fully expanded pill set never
              // overflows the column on small screens.
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state.agentMode)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: FilterChip(
                            avatar:
                                const Icon(Icons.casino_outlined, size: 16),
                            label: const Text('Surprise me'),
                            selected: facets.surpriseMe,
                            onSelected: (v) =>
                                _updateFacets(facets.copyWith(surpriseMe: v)),
                          ),
                        ),
                      ..._facetSections(facets),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showNarration)
          NarrationStrip(lines: state.narration, active: state.isAgentActive),
        if (state.agentMode && state.digging.isNotEmpty) ...[
          const SizedBox(height: 4),
          DiggingStrip(digging: state.digging),
        ],
        Expanded(child: _content(state)),
      ],
    );
  }

  List<Widget> _facetSections(FinderFacets facets) {
    Widget chips(List<FacetOption> options, String? group,
            void Function(String?) onChanged) =>
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              FacetChoiceChip(
                  option: o, groupValue: group, onChanged: onChanged),
          ],
        );

    return [
      FacetSection(
        title: 'Occasion',
        child: chips(kOccasions, facets.occasion,
            (v) => _updateFacets(facets.copyWith(occasion: v))),
      ),
      FacetSection(
        title: 'Time',
        child: chips(kTimes, facets.timeBudget,
            (v) => _updateFacets(facets.copyWith(timeBudget: v))),
      ),
      FacetSection(
        title: 'Protein',
        child: chips(kProteins, facets.protein,
            (v) => _updateFacets(facets.copyWith(protein: v))),
      ),
      FacetSection(
        title: 'Cuisine',
        child: SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kCuisines.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) => Center(
              child: FacetChoiceChip(
                option: kCuisines[i],
                groupValue: facets.cuisine,
                onChanged: (v) => _updateFacets(facets.copyWith(cuisine: v)),
              ),
            ),
          ),
        ),
      ),
      FacetSection(
        title: 'Use what I have',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ingredientController,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Add an ingredient…',
                      prefixIcon: Icon(Icons.kitchen_outlined),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addIngredient(facets),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () => _addIngredient(facets),
                  icon: const Icon(Icons.add),
                  tooltip: 'Add ingredient',
                ),
              ],
            ),
            if (facets.useWhatIHave.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final ing in facets.useWhatIHave)
                    InputChip(
                      label: Text(ing),
                      onDeleted: () => _updateFacets(facets.copyWith(
                          useWhatIHave: facets.useWhatIHave
                              .where((i) => i != ing)
                              .toList())),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    ];
  }

  // ---- Content (shared by both modes) -------------------------------------

  Widget _content(SearchState state) {
    if (state.isLimitReached) {
      return SearchLimitState(
        message: state.error ??
            'You’ve reached your search limit. Upgrade to Premium for '
                'unlimited searches.',
        onUpgrade: () => context.pushNamed('subscription'),
      );
    }
    if (state.error != null &&
        (!state.agentMode || state.phase == FinderPhase.error)) {
      return _ErrorState(message: state.error!, onRetry: _runSearch);
    }
    if (state.agentMode && state.phase == FinderPhase.empty) {
      return FinderEmptyState(broaden: state.broaden, onBroaden: _refine);
    }
    if (!state.hasSearched) {
      return _idleState(state);
    }
    if (state.results.isNotEmpty) {
      return _resultsView(state)
          .animate(key: const ValueKey('results-reveal'))
          .fadeIn(duration: 250.ms);
    }
    // Searched, nothing painted yet: a live run's brief pre-results window,
    // or a finished search with no hits.
    if (state.agentMode && state.isAgentActive) {
      return const AgentWorkingView(found: []);
    }
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return _noResultsState();
  }

  /// Pre-search body: bar-first with a couple of tap-first on-ramps (the
  /// facet pills wait in the Filters expander).
  Widget _idleState(SearchState state) {
    final theme = Theme.of(context);
    final diet = state.agentMode
        ? familyDietSummary(ref.watch(familyProvider).valueOrNull)
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      children: [
        Text(
          state.agentMode
              ? 'Real recipes, found for you'
              : 'Search for recipes across the web',
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          state.agentMode
              ? "Type anything — we'll search the internet (TikTok included), "
                  'read the roundups, and curate the best matches for you.'
              : 'Real recipes from thousands of sites across the internet — '
                  'including TikTok.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        if (diet != null) ...[
          const SizedBox(height: 16),
          DietaryChip(
            summary: diet,
            onTap: () => context.pushNamed('family'),
          ),
        ],
        if (state.agentMode) ...[
          const SizedBox(height: 16),
          SurpriseTile(
            selected: state.facets.surpriseMe,
            onTap: () => _runSuggestion('', surprise: true),
          ),
          const SizedBox(height: 20),
          Text(
            'Or start from a mood',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in const [
                'cozy comfort food',
                'quick weeknight dinner',
                'something new with chicken',
                'impressive but easy',
              ])
                ActionChip(
                  label: Text(s),
                  onPressed: () => _runSuggestion(s),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _noResultsState() {
    final theme = Theme.of(context);
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
            Text('Try different keywords or check your spelling.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  // ---- Shared results view (immersive / list) ----------------------------

  Widget _resultsView(SearchState state) {
    return state.viewMode == SearchViewMode.immersive
        ? _immersiveView(state)
        : _listView(state);
  }

  Widget _immersiveView(SearchState state) {
    // Keep the tail loading page up while a load-more stream is in flight
    // (its items land live behind it as they stream).
    final itemCount = state.results.length +
        ((state.hasMore || state.isLoadingMore) ? 1 : 0);
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: itemCount,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            if (index >= state.results.length) {
              return const _FullScreenLoadingPage();
            }
            final result = state.results[index];
            return _FullScreenResultPage(
              result: result,
              onTap: () => _previewResult(result),
            );
          },
        ),
        // The curated Top Picks live in the list view — surface them from the
        // feed with a floating pill once they land.
        if (state.topPicks.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Center(
              child: _TopPicksPill(onTap: _showTopPicks)
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.5, end: 0, duration: 300.ms),
            ),
          ),
      ],
    );
  }

  Widget _listView(SearchState state) {
    final picks = state.topPicks;
    final pickUrls =
        picks.map((r) => r.sourceUrl).whereType<String>().toSet();
    // Below the picks section, avoid re-listing the same recipes.
    final rest = picks.isEmpty
        ? state.results
        : state.results
            .where(
                (r) => r.sourceUrl == null || !pickUrls.contains(r.sourceUrl))
            .toList();

    final rows = <Widget>[];
    if (picks.isNotEmpty) {
      rows.add(const _SectionHeader(
        icon: Icons.star_rounded,
        title: 'Top picks for you',
        subtitle: 'Curated from everything found — including inside roundups',
      ));
      for (var i = 0; i < picks.length; i++) {
        final result = picks[i];
        rows.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FinderShortlistCard(
            result: result,
            index: i,
            onTap: () => _previewResult(result),
          ),
        ));
      }
      if (rest.isNotEmpty) {
        rows.add(const _SectionHeader(
          icon: Icons.travel_explore,
          title: 'Everything found',
        ));
      }
    }
    for (var i = 0; i < rest.length; i++) {
      final result = rest[i];
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FinderShortlistCard(
          result: result,
          index: picks.length + i,
          onTap: () => _previewResult(result),
        ),
      ));
    }
    if (state.isLoadingMore) {
      rows.add(const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ));
    }

    return ListView(
      controller: _listScrollController,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      children: rows,
    );
  }
}

// ---------------------------------------------------------------------------
// List section header (★ Top picks / Everything found)
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Immersive-view floating pill surfacing the Top Picks section
// ---------------------------------------------------------------------------

class _TopPicksPill extends StatelessWidget {
  const _TopPicksPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primaryContainer,
      elevation: 4,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Top picks ready',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App-bar agent toggle
// ---------------------------------------------------------------------------

class _AgentToggle extends StatelessWidget {
  const _AgentToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_awesome,
            size: 18,
            color: value
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 2),
        Text('Agent', style: theme.textTheme.labelMedium),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Full-screen (immersive) page for a single result
// ---------------------------------------------------------------------------

class _FullScreenResultPage extends StatelessWidget {
  const _FullScreenResultPage({required this.result, required this.onTap});

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
          if (result.imageUrl != null)
            CachedNetworkImage(
              imageUrl: result.imageUrl!,
              memCacheWidth: 1080,
              fit: BoxFit.cover,
              placeholder: (_, __) => _FullScreenPlaceholder(theme: theme),
              errorWidget: (_, __, ___) => _FullScreenPlaceholder(theme: theme),
            )
          else
            _FullScreenPlaceholder(theme: theme),
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
                  colors: [Colors.transparent, Color(0xCC000000)],
                ),
              ),
            ),
          ),
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
                  if (isPendingExtraction(result.extractionStatus) ||
                      result.extractionStatus == 'failed') ...[
                    ExtractionStatusBadge(status: result.extractionStatus!),
                    const SizedBox(height: 10),
                  ],
                  if (result.rating != null) ...[
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          final filled = i < result.rating!.round();
                          return Icon(
                            filled
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 18,
                            color: filled
                                ? const Color(0xFFF9A825)
                                : Colors.white38,
                          );
                        }),
                        const SizedBox(width: 6),
                        Text(
                          result.rating!.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
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
                  Row(
                    children: [
                      if (result.sourceDomain != null)
                        Flexible(
                          child: Text(
                            result.sourceDomain!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ),
                    ],
                  ),
                  // Agent rationale ("why this fits").
                  if (result.reason != null && result.reason!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '✨ ${result.reason!}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (result.via != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'found inside ‘${result.via!}’',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.white54),
                      ),
                    ],
                  ] else if (result.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      result.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white60),
                    ),
                  ],
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
        child: Icon(Icons.restaurant,
            size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.25)),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
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
            Icon(Icons.error_outline,
                size: 48, color: theme.colorScheme.error.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('Search failed', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

