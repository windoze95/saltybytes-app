import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/allergen.dart';
import '../../models/finder_session.dart';
import '../../models/recipe.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../utils/unit_converter.dart';
import 'finder_provider.dart';

class PreviewException implements Exception {
  const PreviewException({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

/// Thrown when a preview request discovers a multi-recipe page.
/// The caller should expand the individual cards into the results list.
class MultiRecipeException implements Exception {
  const MultiRecipeException({
    required this.sourceResult,
    required this.resolution,
  });

  final WebSearchResult sourceResult;
  final MultiRecipeResolution resolution;

  @override
  String toString() =>
      'Multi-recipe page detected: ${resolution.recipes.length} recipes';
}

class WebSearchResult {
  const WebSearchResult({
    required this.title,
    this.sourceUrl,
    this.sourceDomain,
    this.imageUrl,
    this.description,
    this.rating,
    this.cookTimeMinutes,
    this.familySafetyChecks = const [],
    this.extractionStatus,
    this.reason,
    this.via,
  });

  final String title;
  final String? sourceUrl;
  final String? sourceDomain;
  final String? imageUrl;
  final String? description;
  final double? rating;
  final int? cookTimeMinutes;
  final List<FamilySafetyCheck> familySafetyChecks;

  /// For cards expanded from a multi-recipe page: the per-card extraction
  /// status ("pending"/"extracting"/"done"/"failed"). null for normal results.
  final String? extractionStatus;

  /// The agent's one-line rationale ("why this fits"). Only set on agent-mode
  /// results; plain search omits it (null).
  final String? reason;

  /// For recipes the agent mined out of a roundup/collection: the collection's
  /// title ("found inside '50 Best Weeknight Dinners'"). null otherwise.
  final String? via;

  WebSearchResult copyWith({
    String? extractionStatus,
    String? reason,
    List<FamilySafetyCheck>? familySafetyChecks,
  }) {
    return WebSearchResult(
      title: title,
      sourceUrl: sourceUrl,
      sourceDomain: sourceDomain,
      imageUrl: imageUrl,
      description: description,
      rating: rating,
      cookTimeMinutes: cookTimeMinutes,
      familySafetyChecks: familySafetyChecks ?? this.familySafetyChecks,
      extractionStatus: extractionStatus ?? this.extractionStatus,
      reason: reason ?? this.reason,
      via: via,
    );
  }

  factory WebSearchResult.fromJson(Map<String, dynamic> json) {
    // The backend serializes image_url without omitempty, so hits with no
    // thumbnail arrive as "" — coerce to null so render sites fall back to
    // the placeholder instead of feeding an empty URL to the image widget.
    final imageUrl = json['image_url'] as String?;
    return WebSearchResult(
      title: json['title'] as String? ?? 'Untitled',
      sourceUrl: json['source_url'] as String?,
      sourceDomain: json['source_domain'] as String?,
      imageUrl: (imageUrl == null || imageUrl.isEmpty) ? null : imageUrl,
      description: json['description'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      cookTimeMinutes: json['cook_time_minutes'] as int?,
      familySafetyChecks: (json['family_safety_checks'] as List?)
              ?.map(
                (e) => FamilySafetyCheck.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      reason: json['reason'] as String?,
      via: json['via'] as String?,
    );
  }
}

/// A roundup/collection the agent is digging into during a run, shown as a
/// chip in the digging strip ("📖 50 Best Weeknight Dinners ✓ 3").
class DiggingCollection {
  const DiggingCollection({
    required this.title,
    this.folded = 0,
    this.done = false,
  });

  final String title;

  /// How many individual recipes have been folded out of it so far.
  final int folded;

  /// Whether its recipes have landed (an expanded batch arrived).
  final bool done;

  DiggingCollection copyWith({int? folded, bool? done}) => DiggingCollection(
        title: title,
        folded: folded ?? this.folded,
        done: done ?? this.done,
      );
}

/// A single recipe card from a resolved multi-recipe page.
class MultiRecipeCard {
  const MultiRecipeCard({
    required this.title,
    this.imageUrl,
    this.description,
    this.sourceUrl,
    required this.extractionStatus,
  });

  final String title;
  final String? imageUrl;
  final String? description;
  final String? sourceUrl;
  final String extractionStatus; // "pending", "extracting", "done", "failed"

  factory MultiRecipeCard.fromJson(Map<String, dynamic> json) {
    return MultiRecipeCard(
      title: json['title'] as String? ?? 'Untitled',
      imageUrl: json['image_url'] as String?,
      description: json['description'] as String?,
      sourceUrl: json['source_url'] as String?,
      extractionStatus: json['extraction_status'] as String? ?? 'pending',
    );
  }

  /// Convert to a WebSearchResult for display in the card stack.
  WebSearchResult toSearchResult() {
    String? domain;
    if (sourceUrl != null) {
      try {
        domain = Uri.parse(sourceUrl!).host.replaceFirst('www.', '');
      } catch (_) {}
    }
    return WebSearchResult(
      title: title,
      sourceUrl: sourceUrl,
      sourceDomain: domain,
      imageUrl: imageUrl,
      description: description,
      extractionStatus: extractionStatus,
    );
  }
}

/// Resolution state for a multi-recipe page.
class MultiRecipeResolution {
  const MultiRecipeResolution({
    required this.multiId,
    required this.sourceUrl,
    required this.status,
    this.recipes = const [],
  });

  final String multiId;
  final String sourceUrl;
  final String status; // "resolving", "resolved", "failed"
  final List<MultiRecipeCard> recipes;

  factory MultiRecipeResolution.fromJson(Map<String, dynamic> json) {
    return MultiRecipeResolution(
      multiId: json['multi_id'] as String? ?? '',
      sourceUrl: json['source_url'] as String? ?? '',
      status: json['status'] as String? ?? 'resolving',
      recipes: (json['recipes'] as List?)
              ?.map((e) => MultiRecipeCard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class RecipePreview {
  const RecipePreview({
    required this.title,
    this.ingredients = const [],
    this.instructions = const [],
    this.cookTime,
    this.portions,
    this.portionSize,
    this.sourceUrl,
    this.hashtags = const [],
    this.imagePrompt,
    this.linkedSuggestions = const [],
    this.unitSystem,
    this.fromCache = false,
  });

  final String title;
  final List<PreviewIngredient> ingredients;
  final List<String> instructions;
  final int? cookTime;
  final int? portions;
  final String? portionSize;
  final String? sourceUrl;
  final List<String> hashtags;
  final String? imagePrompt;
  final List<String> linkedSuggestions;
  final String? unitSystem;

  /// True when the backend served this from its saved-recipe cache (an instant
  /// load) rather than freshly extracting it.
  final bool fromCache;

  String? get sourceDomain {
    if (sourceUrl == null) return null;
    try {
      return Uri.parse(sourceUrl!).host.replaceFirst('www.', '');
    } catch (_) {
      return null;
    }
  }

  factory RecipePreview.fromJson(Map<String, dynamic> json,
      {bool fromCache = false}) {
    return RecipePreview(
      fromCache: fromCache,
      title: json['title'] as String? ?? 'Untitled',
      ingredients: (json['ingredients'] as List?)
              ?.map(
                (e) => PreviewIngredient.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      instructions:
          (json['instructions'] as List?)?.map((e) => e as String).toList() ??
              [],
      cookTime: json['cook_time'] as int?,
      portions: json['portions'] as int?,
      portionSize: json['portion_size'] as String?,
      sourceUrl: json['source_url'] as String?,
      hashtags:
          (json['hashtags'] as List?)?.map((e) => e as String).toList() ?? [],
      imagePrompt: json['image_prompt'] as String?,
      linkedSuggestions: (json['linked_recipe_suggestions'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      unitSystem: json['unit_system'] as String?,
    );
  }

  /// Builds the snake_case manualImportRequest body for
  /// POST /v1/recipes/import/manual, preserving the source's detected
  /// unit system and metric measurements (contract C6).
  Map<String, dynamic> toManualImportJson({String? imageUrl}) {
    return {
      'title': title,
      'ingredients': ingredients
          .map((i) => {
                'name': i.name,
                'unit': i.unit,
                'amount': i.amount,
                if (i.metricUnit != null) 'metric_unit': i.metricUnit,
                if (i.metricAmount != null) 'metric_amount': i.metricAmount,
                if (i.originalText != null) 'original_text': i.originalText,
              })
          .toList(),
      'instructions': instructions,
      'cook_time': cookTime ?? 0,
      'portions': portions ?? 0,
      'portion_size': portionSize ?? '',
      'hashtags': hashtags,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (unitSystem != null && unitSystem!.isNotEmpty)
        'unit_system': unitSystem,
      if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
    };
  }
}

class PreviewIngredient {
  const PreviewIngredient({
    required this.name,
    this.unit,
    this.amount,
    this.metricUnit,
    this.metricAmount,
    this.originalText,
  });

  final String name;
  final String? unit;
  final double? amount;
  final String? metricUnit;
  final double? metricAmount;
  final String? originalText;

  factory PreviewIngredient.fromJson(Map<String, dynamic> json) {
    return PreviewIngredient(
      name: json['name'] as String? ?? '',
      unit: json['unit'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      metricUnit: json['metric_unit'] as String?,
      metricAmount: (json['metric_amount'] as num?)?.toDouble(),
      originalText: json['original_text'] as String?,
    );
  }

  String get displayText {
    // Pre-import preview shows the source measurement, formatted consistently
    // with the recipe screen (cooking fractions for US volume, clean decimals
    // for metric). No viewer-system alternate yet — that resolves after import.
    final qty = formatIngredientQuantity(Ingredient(
      name: name,
      amount: amount,
      unit: unit,
      metricUnit: metricUnit,
      metricAmount: metricAmount,
      originalText: originalText,
    ));
    return qty.isEmpty ? name : '$qty $name';
  }
}

/// How results are displayed. Both modes are shared by agent + plain search:
/// an immersive full-screen PageView, or a curated photo list.
enum SearchViewMode { immersive, list }

/// The unified Search state. It carries the classic paginated search fields AND
/// the "agent" (finder) fields — the [agentMode] flag decides which path
/// [SearchNotifier.search]/[SearchNotifier.loadMore] take.
class SearchState {
  const SearchState({
    this.agentMode = true,
    this.facets = const FinderFacets(),
    this.viewMode = SearchViewMode.immersive,
    this.query = '',
    this.results = const [],
    this.topPicks = const [],
    this.digging = const [],
    this.isLoading = false,
    this.error,
    this.hasSearched = false,
    this.nextOffset = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.phase = FinderPhase.idle,
    this.narration = const [],
    this.refineChips = const [],
    this.broaden = const [],
    this.isLimitReached = false,
  });

  /// Agent mode ON (default): search-bar-first with the agent layered on top —
  /// SSE `/recipes/find` paints real results instantly, then enhances them
  /// (reasons, family-safety, digging, top picks). OFF: the same bar →
  /// `GET /recipes/search` (plain, paginated, no enhancement).
  final bool agentMode;

  /// The facet selections + typed details (shared by both modes;
  /// plain mode flattens them into a keyword query).
  final FinderFacets facets;
  final SearchViewMode viewMode;

  final String query;

  /// Everything found, painted LIVE as the run streams (instant results →
  /// annotated shortlist → recipes dug out of collections).
  final List<WebSearchResult> results;

  /// The agent's final curated top picks (direct + mined re-ranked together,
  /// each with a fresh rationale). Lands once, near the end of a run.
  final List<WebSearchResult> topPicks;

  /// Collections the agent is digging into this run, in dig order.
  final List<DiggingCollection> digging;

  final bool isLoading;
  final String? error;
  final bool hasSearched;
  final int nextOffset;
  final bool hasMore;
  final bool isLoadingMore;

  // Agent-only run fields.
  final FinderPhase phase;
  final List<String> narration;
  final List<String> refineChips;
  final List<String> broaden;
  final bool isLimitReached;

  bool get isTerminalPhase =>
      phase == FinderPhase.done ||
      phase == FinderPhase.empty ||
      phase == FinderPhase.error;

  /// The agent run is mid-flight (streaming), so the narration strip should
  /// show a live "working" spinner.
  bool get isAgentActive =>
      agentMode && phase != FinderPhase.idle && !isTerminalPhase;

  bool get isEmptyResult => hasSearched && results.isEmpty && !isLoading;

  SearchState copyWith({
    bool? agentMode,
    FinderFacets? facets,
    SearchViewMode? viewMode,
    String? query,
    List<WebSearchResult>? results,
    List<WebSearchResult>? topPicks,
    List<DiggingCollection>? digging,
    bool? isLoading,
    String? error,
    bool? hasSearched,
    int? nextOffset,
    bool? hasMore,
    bool? isLoadingMore,
    FinderPhase? phase,
    List<String>? narration,
    List<String>? refineChips,
    List<String>? broaden,
    bool? isLimitReached,
  }) {
    return SearchState(
      agentMode: agentMode ?? this.agentMode,
      facets: facets ?? this.facets,
      viewMode: viewMode ?? this.viewMode,
      query: query ?? this.query,
      results: results ?? this.results,
      topPicks: topPicks ?? this.topPicks,
      digging: digging ?? this.digging,
      isLoading: isLoading ?? this.isLoading,
      // Cleared unless explicitly provided (matches the original idiom).
      error: error,
      hasSearched: hasSearched ?? this.hasSearched,
      nextOffset: nextOffset ?? this.nextOffset,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      phase: phase ?? this.phase,
      narration: narration ?? this.narration,
      refineChips: refineChips ?? this.refineChips,
      broaden: broaden ?? this.broaden,
      isLimitReached: isLimitReached ?? this.isLimitReached,
    );
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SearchNotifier(apiClient: apiClient);
});

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const SearchState());

  final ApiClient _apiClient;

  // Cache warming: source URLs already sent to /warm during this search, and
  // whether a status-poll loop is currently running.
  final Set<String> _warmRequested = {};
  bool _warmPolling = false;

  // A new run (search/refine/toggle/clear) bumps the sequence and cancels the
  // previous SSE stream, so a stale stream can never write over fresh state.
  int _runSeq = 0;
  CancelToken? _sseCancel;

  int _newRun() {
    _sseCancel?.cancel('superseded by a new search');
    _sseCancel = null;
    return ++_runSeq;
  }

  // ---- Input mutation (the screen drives these) --------------------------

  /// Flips agent ⇄ plain and resets the run (keeps the chosen facets + view).
  void setAgentMode(bool value) {
    if (value == state.agentMode) return;
    _newRun();
    state = SearchState(
      agentMode: value,
      facets: state.facets,
      viewMode: state.viewMode,
    );
  }

  void setViewMode(SearchViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void setFacets(FinderFacets facets) {
    state = state.copyWith(facets: facets);
  }

  /// Sets the typed/spoken details (stored on the facets' freeText).
  void setQuery(String text) {
    state = state.copyWith(facets: state.facets.copyWith(freeText: text));
  }

  /// Repopulates Search from a saved [FinderSession] — its intent, results and
  /// narration — as a finished agent run. Does NOT re-run the search.
  void restoreFromSession(FinderSession session) {
    _newRun();
    _warmRequested.clear();
    state = SearchState(
      agentMode: true,
      facets: session.intent,
      viewMode: state.viewMode,
      query: session.intent.toKeywordQuery(),
      results: session.results,
      hasSearched: true,
      phase: FinderPhase.done,
      narration: session.narration,
      nextOffset: session.results.length,
      hasMore: false,
    );
  }

  // ---- Search (branches on agentMode) ------------------------------------

  Future<void> search() async {
    if (state.agentMode) {
      await _runAgent();
    } else {
      await _runPlain();
    }
  }

  Future<void> loadMore() async {
    if (state.agentMode) {
      await _loadMoreAgent();
    } else {
      await _loadMorePlain();
    }
  }

  // ---- Agent (SSE /recipes/find) -----------------------------------------

  Future<void> _runAgent({
    FinderRefine? refine,
    List<String>? seedNarration,
  }) async {
    final seq = _newRun();
    _warmRequested.clear();
    state = state.copyWith(
      isLoading: true,
      error: null,
      hasSearched: true,
      results: const [],
      topPicks: const [],
      digging: const [],
      narration: seedNarration ?? const [],
      refineChips: const [],
      broaden: const [],
      isLimitReached: false,
      phase: FinderPhase.searching,
      nextOffset: 0,
      hasMore: false,
      isLoadingMore: false,
      query: state.facets.toKeywordQuery(),
    );
    await _streamAgent(state.facets.toRequestJson(refine: refine), seq: seq);
  }

  /// Re-runs the current facets with an added [constraint] (a refine chip).
  Future<void> refine(String constraint) async {
    if (!state.agentMode) return;
    await _runAgent(
      refine: FinderRefine(constraint: constraint),
      seedNarration: ['Refining: $constraint…'],
    );
  }

  Future<void> _loadMoreAgent() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    await _streamAgent(
      state.facets.toRequestJson(offset: state.nextOffset),
      seq: _runSeq,
      loadMore: true,
    );
  }

  Future<void> _streamAgent(Map<String, dynamic> body,
      {required int seq, bool loadMore = false}) async {
    final cancel = CancelToken();
    _sseCancel = cancel;
    try {
      final resp = await _apiClient.dio.post(
        ApiEndpoints.find,
        data: body,
        cancelToken: cancel,
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      final stream = (resp.data as ResponseBody).stream.cast<List<int>>();
      await for (final event in parseFinderSse(stream)) {
        if (!mounted || seq != _runSeq) return; // superseded by a newer run
        if (loadMore) {
          _applyAgentLoadMoreEvent(event);
        } else {
          _applyAgentEvent(event);
        }
      }
    } on DioException catch (e) {
      if (!mounted || seq != _runSeq) return;
      if (CancelToken.isCancel(e)) return; // superseded, not a failure
      _applyAgentDioError(e, loadMore: loadMore);
    } catch (_) {
      if (!mounted || seq != _runSeq) return;
      if (loadMore) {
        state = state.copyWith(isLoadingMore: false);
      } else {
        _failFreshRun(
            'Something went wrong finding recipes. Please try again.');
      }
    }
  }

  void _applyAgentEvent(FinderEvent e) {
    switch (e.type) {
      case 'searching':
        final q = (e.query ?? '').trim();
        state = state.copyWith(
          phase: FinderPhase.searching,
          narration: [
            ...state.narration,
            q.isEmpty
                ? '\u{1F50D} Searching for recipes…'
                : '\u{1F50D} Searching “$q”…',
          ],
        );
      case 'found':
        final c = e.count ?? 0;
        final suffix = e.fromCache ? ' (instant — from cache)' : '';
        state = state.copyWith(
          phase: FinderPhase.found,
          narration: [
            ...state.narration,
            'Found $c real ${c == 1 ? 'recipe' : 'recipes'}$suffix',
          ],
        );
      case 'results':
        // Instant paint: the real candidates land tappable BEFORE any model
        // call. Everything after this enhances in place.
        state = state.copyWith(
          results: e.items,
          isLoading: false,
          hasMore: e.hasMore ?? state.hasMore,
        );
        warmAhead(0);
      case 'filtering':
        // Neutral copy — never assumes the user set up a family profile
        // (dietary checks still run server-side when one exists).
        state = state.copyWith(
          phase: FinderPhase.filtering,
          narration: [
            ...state.narration,
            'Picking the best matches…',
          ],
        );
      case 'shortlist':
        // Enhancement patch: attach reasons/safety to the painted results (in
        // place, no reorder — the picks section carries the curation) and
        // append any ranked results the instant paint didn't include.
        _mergeShortlist(e.items);
        state = state.copyWith(
          phase: FinderPhase.shortlist,
          hasMore: e.hasMore ?? false,
          nextOffset: e.items.length,
        );
      case 'digging':
        // The agent is opening a collection ("23 Best Weeknight Dinners") to
        // fold individual recipes out of it. The collection itself is pulled
        // from the painted results (it's a dig source, not a recipe).
        final title = (e.collectionTitle ?? '').trim();
        state = state.copyWith(
          phase: FinderPhase.digging,
          results: title.isEmpty
              ? state.results
              : state.results.where((r) => r.title != title).toList(),
          digging: [
            ...state.digging,
            if (title.isNotEmpty) DiggingCollection(title: title),
          ],
          narration: [
            ...state.narration,
            title.isEmpty
                ? '\u{1F37D} Opening a recipe collection…'
                : '\u{1F37D} Opening ‘$title’…',
          ],
        );
      case 'expanded':
        // Recipes folded out of a collection land live, with provenance.
        _appendResults(e.items);
        final title = (e.collectionTitle ?? '').trim();
        state = state.copyWith(
          digging: [
            for (final d in state.digging)
              d.title == title
                  ? d.copyWith(done: true, folded: d.folded + e.items.length)
                  : d,
          ],
        );
      case 'picks':
        // The agent's final curated top picks (direct + mined re-ranked
        // together). Lands once as its own section — the browsing list stays
        // stable underneath.
        state = state.copyWith(topPicks: e.items);
      case 'warming':
        state = state.copyWith(
          phase: FinderPhase.warming,
          narration: [...state.narration, 'Getting the top picks ready…'],
        );
      case 'refine_ready':
        state = state.copyWith(
          phase: FinderPhase.refineReady,
          refineChips: e.chips,
          broaden: e.broaden,
        );
      case 'done':
        state = state.copyWith(
          phase: FinderPhase.done,
          isLoading: false,
          digging: [
            for (final d in state.digging) d.copyWith(done: true),
          ],
        );
      case 'empty':
        state = state.copyWith(
          phase: FinderPhase.empty,
          results: const [],
          topPicks: const [],
          broaden: e.broaden,
          isLoading: false,
          hasMore: false,
        );
      case 'error':
        _failFreshRun((e.error == null || e.error!.isEmpty)
            ? 'Something went wrong finding recipes. Please try again.'
            : e.error!);
    }
  }

  /// Terminal failure of a fresh agent run. If real results already painted,
  /// the run found recipes before dying — keep them on screen rather than
  /// replacing them with an error screen. Otherwise surface the error state.
  void _failFreshRun(String message) {
    if (state.results.isNotEmpty) {
      state = state.copyWith(
        phase: FinderPhase.done,
        isLoading: false,
        digging: [for (final d in state.digging) d.copyWith(done: true)],
      );
      return;
    }
    state = state.copyWith(
      phase: FinderPhase.error,
      isLoading: false,
      error: message,
    );
  }

  void _applyAgentLoadMoreEvent(FinderEvent e) {
    switch (e.type) {
      case 'results':
        // Next-page candidates land live behind the loading tail.
        _appendResults(e.items);
        state = state.copyWith(hasMore: e.hasMore ?? state.hasMore);
      case 'shortlist':
        _mergeShortlist(e.items);
        state = state.copyWith(
          hasMore: e.hasMore ?? false,
          nextOffset: state.nextOffset + e.items.length,
        );
      case 'digging':
        final title = (e.collectionTitle ?? '').trim();
        if (title.isNotEmpty) {
          state = state.copyWith(
            results: state.results.where((r) => r.title != title).toList(),
          );
        }
      case 'expanded':
        _appendResults(e.items);
      case 'done':
        state = state.copyWith(isLoadingMore: false);
      case 'empty':
        state = state.copyWith(isLoadingMore: false, hasMore: false);
      case 'error':
        state = state.copyWith(isLoadingMore: false);
      // narration/found/filtering/warming/picks/refine_ready ignored
    }
  }

  /// Attaches the ranked shortlist's reasons/safety to already-painted results
  /// (matched by sourceUrl, in place — no reorder) and appends ranked results
  /// the instant paint didn't include (e.g. a pattern false positive).
  void _mergeShortlist(List<WebSearchResult> items) {
    if (items.isEmpty) return;
    final byUrl = <String, WebSearchResult>{
      for (final it in items)
        if (it.sourceUrl != null) it.sourceUrl!: it,
    };
    final seen = <String>{};
    final merged = state.results.map((r) {
      final match = r.sourceUrl == null ? null : byUrl[r.sourceUrl];
      if (match == null) return r;
      seen.add(r.sourceUrl!);
      return r.copyWith(
        reason: match.reason,
        familySafetyChecks: match.familySafetyChecks,
      );
    }).toList();
    final appended = items
        .where((it) => it.sourceUrl == null || !seen.contains(it.sourceUrl))
        .toList();
    state = state.copyWith(results: [...merged, ...appended]);
    _warmNew(appended);
  }

  /// Appends new results live, deduped by sourceUrl against what's shown.
  void _appendResults(List<WebSearchResult> items) {
    if (items.isEmpty) return;
    final existing =
        state.results.map((r) => r.sourceUrl).whereType<String>().toSet();
    final added = items
        .where((r) => r.sourceUrl == null || !existing.contains(r.sourceUrl))
        .toList();
    if (added.isEmpty) return;
    state = state.copyWith(results: [...state.results, ...added]);
    _warmNew(added);
  }

  void _applyAgentDioError(DioException e, {required bool loadMore}) {
    if (loadMore) {
      state = state.copyWith(isLoadingMore: false);
      return;
    }
    if (e.response?.statusCode == 403) {
      state = state.copyWith(
        phase: FinderPhase.error,
        isLoading: false,
        isLimitReached: true,
        error: 'You’ve reached your search limit. Upgrade to Premium for '
            'unlimited searches.',
      );
      return;
    }
    _failFreshRun(userFacingErrorMessage(
        e, 'Something went wrong finding recipes. Please try again.'));
  }

  // ---- Plain (GET /recipes/search) ---------------------------------------

  Future<void> _runPlain() async {
    final query = state.facets.toKeywordQuery();
    if (query.trim().isEmpty) return;
    _newRun(); // cancel any in-flight agent stream
    _warmRequested.clear();

    state = state.copyWith(
      query: query,
      isLoading: true,
      error: null,
      hasSearched: true,
      nextOffset: 0,
      hasMore: true,
      isLoadingMore: false,
      phase: FinderPhase.idle,
      narration: const [],
      refineChips: const [],
      broaden: const [],
      isLimitReached: false,
    );

    try {
      final response = await _apiClient.get(
        ApiEndpoints.search,
        queryParameters: {'q': query},
      );

      final data = response.data;
      List<WebSearchResult> results = [];
      bool hasMore = false;

      if (data is Map<String, dynamic>) {
        if (data['results'] is List) {
          results = (data['results'] as List)
              .map((r) => WebSearchResult.fromJson(r as Map<String, dynamic>))
              .toList();
        }
        hasMore = data['has_more'] as bool? ?? false;
      } else if (data is List) {
        results = data
            .map((r) => WebSearchResult.fromJson(r as Map<String, dynamic>))
            .toList();
      }

      state = state.copyWith(
        results: results,
        isLoading: false,
        nextOffset: results.length,
        hasMore: hasMore,
      );

      // Pre-warm the first few results so early taps are instant.
      warmAhead(0);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: userFacingErrorMessage(
            e, 'Something went wrong searching. Please try again.'),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong searching. Please try again.',
      );
    }
  }

  Future<void> _loadMorePlain() async {
    if (state.isLoadingMore || !state.hasMore || state.query.isEmpty) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final response = await _apiClient.get(
        ApiEndpoints.search,
        queryParameters: {
          'q': state.query,
          'offset': state.nextOffset.toString(),
        },
      );

      final data = response.data;
      List<WebSearchResult> newResults = [];
      bool hasMore = false;

      if (data is Map<String, dynamic>) {
        if (data['results'] is List) {
          newResults = (data['results'] as List)
              .map((r) => WebSearchResult.fromJson(r as Map<String, dynamic>))
              .toList();
        }
        hasMore = data['has_more'] as bool? ?? false;
      }

      // Advance offset by the raw page size before dedup so we don't
      // re-request the same range when duplicates are removed.
      final fetchedCount = newResults.length;

      // Deduplicate by sourceUrl
      final existingUrls =
          state.results.map((r) => r.sourceUrl).whereType<String>().toSet();
      newResults.removeWhere(
          (r) => r.sourceUrl != null && existingUrls.contains(r.sourceUrl));

      state = state.copyWith(
        results: [...state.results, ...newResults],
        isLoadingMore: false,
        nextOffset: state.nextOffset + fetchedCount,
        hasMore: hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Preview a search result. If the backend detects multiple recipes on the
  /// page, throws a [MultiRecipeException] with the individual cards so the
  /// caller can expand them into the results list.
  Future<RecipePreview> previewResult(WebSearchResult result) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.previewFromUrl,
        data: {'url': result.sourceUrl},
        options: Options(receiveTimeout: ApiTimeouts.aiGeneration),
      );
      final data = response.data as Map<String, dynamic>;

      // Check for multi-recipe response
      if (data['is_multi'] == true) {
        final resolution = MultiRecipeResolution.fromJson(data);
        throw MultiRecipeException(
          sourceResult: result,
          resolution: resolution,
        );
      }

      final recipe = data['recipe'] as Map<String, dynamic>;
      final fromCache = data['from_cache'] as bool? ?? false;
      return RecipePreview.fromJson(recipe, fromCache: fromCache);
    } on MultiRecipeException {
      rethrow;
    } on DioException catch (e) {
      final apiError = e.error;
      if (apiError is ApiError) {
        switch (apiError.errorCode) {
          case 'site_blocked':
            throw const PreviewException(
              message:
                  'This website blocks automated access. Try copying the recipe text and using Import from Text instead.',
              code: 'site_blocked',
            );
          case 'not_found':
            throw const PreviewException(
              message: 'Recipe page not found. The URL may have changed.',
              code: 'not_found',
            );
          case 'fetch_failed':
            throw PreviewException(
              message: 'Could not reach the recipe website. Please try again.',
              code: apiError.errorCode,
            );
          default:
            throw PreviewException(
              message: apiError.message,
              code: apiError.errorCode,
            );
        }
      }
      rethrow;
    }
  }

  Future<Recipe> importPreview(RecipePreview preview,
      {String? imageUrl}) async {
    final response = await _apiClient.post(
      ApiEndpoints.importManual,
      data: preview.toManualImportJson(imageUrl: imageUrl),
      options: Options(receiveTimeout: ApiTimeouts.aiGeneration),
    );
    final data = response.data as Map<String, dynamic>;
    final recipe = data['recipe'] as Map<String, dynamic>;
    return Recipe.fromJson(recipe);
  }

  Future<Recipe> importResult(WebSearchResult result) async {
    final response = await _apiClient.post(
      ApiEndpoints.importFromUrl,
      data: {'url': result.sourceUrl},
      options: Options(receiveTimeout: ApiTimeouts.aiGeneration),
    );
    final data = response.data as Map<String, dynamic>;
    final recipe = data['recipe'] as Map<String, dynamic>;
    return Recipe.fromJson(recipe);
  }

  /// Warm the cache for the results around [visibleIndex] (a few ahead of what
  /// the user is looking at) so taps land on already-extracted recipes, and the
  /// shared cache pays off for the next searcher.
  void warmAhead(int visibleIndex) {
    unawaited(_warmWindow(state.results, visibleIndex));
  }

  /// Warm results that just streamed in (the batches are small and bounded)
  /// so they're already extracted by the time the user reaches them.
  void _warmNew(List<WebSearchResult> items) {
    if (items.isEmpty) return;
    unawaited(_warmWindow(items, items.length - 1));
  }

  Future<void> _warmWindow(
      List<WebSearchResult> items, int visibleIndex) async {
    const lookahead = 4;
    if (items.isEmpty) return;
    final end = (visibleIndex + lookahead + 1).clamp(0, items.length);

    final urls = <String>[];
    for (var i = 0; i < end; i++) {
      final r = items[i];
      final url = r.sourceUrl;
      if (url == null || url.isEmpty) continue;
      if (r.extractionStatus == 'done') continue; // already ready
      if (!_warmRequested.add(url)) continue; // already requested this search
      urls.add(url);
    }

    if (urls.isNotEmpty) {
      final statuses = await _warmUrls(urls);
      if (statuses != null) _applyWarmStatuses(statuses);
    }
    _maybeStartWarmPoll();
  }

  Future<Map<String, String>?> _warmUrls(List<String> urls) async {
    try {
      final response =
          await _apiClient.post(ApiEndpoints.warmUrls, data: {'urls': urls});
      final data = response.data as Map<String, dynamic>;
      final statuses = (data['statuses'] as Map?)?.cast<String, dynamic>();
      if (statuses == null) return null;
      return statuses.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return null;
    }
  }

  // Maps a backend warm status onto the badge's extractionStatus. Returns null
  // to leave a result untouched (e.g. "uncached").
  String? _mapWarmStatus(String warm) {
    switch (warm) {
      case 'extracting':
        return 'extracting';
      case 'cached':
      case 'multi':
        return 'done';
      case 'failed':
        // Couldn't pre-warm (e.g. a blocked page). Clear the spinner so it
        // looks like a normal, tappable result rather than stuck "Extracting".
        return 'done';
      default:
        return null;
    }
  }

  // Applies warm statuses to the visible results AND the top-picks section,
  // so both card sets flip their badges in place.
  void _applyWarmStatuses(Map<String, String> statuses) {
    var changed = false;
    List<WebSearchResult> apply(List<WebSearchResult> items) => items.map((r) {
          final url = r.sourceUrl;
          if (url == null) return r;
          final warm = statuses[url];
          if (warm == null) return r;
          final mapped = _mapWarmStatus(warm);
          if (mapped != null && mapped != r.extractionStatus) {
            changed = true;
            return r.copyWith(extractionStatus: mapped);
          }
          return r;
        }).toList();

    final results = apply(state.results);
    final picks = apply(state.topPicks);
    if (changed) state = state.copyWith(results: results, topPicks: picks);
  }

  void _maybeStartWarmPoll() {
    if (_warmPolling) return;
    final extracting = state.results.any(
            (r) => r.extractionStatus == 'extracting') ||
        state.topPicks.any((r) => r.extractionStatus == 'extracting');
    if (!extracting) return;
    _warmPolling = true;
    unawaited(_pollWarmStatuses());
  }

  /// Polls /warm for the still-extracting results until they're all ready (or a
  /// timeout), flipping their badges in place.
  Future<void> _pollWarmStatuses() async {
    try {
      final deadline = DateTime.now().add(const Duration(minutes: 3));
      while (mounted && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        final extracting = <String>[
          for (final r in [...state.results, ...state.topPicks])
            if (r.extractionStatus == 'extracting' && r.sourceUrl != null)
              r.sourceUrl!,
        ];
        if (extracting.isEmpty) return;
        final statuses = await _warmUrls(extracting);
        if (statuses != null) _applyWarmStatuses(statuses);
      }
    } finally {
      _warmPolling = false;
    }
  }

  /// Replace a multi-recipe card with its individual recipe cards.
  /// Returns the index of the first expanded card, or null if nothing changed.
  int? replaceWithExpanded(
      WebSearchResult original, MultiRecipeResolution resolution) {
    if (resolution.recipes.isEmpty) return null;

    final newCards = resolution.recipes.map((c) => c.toSearchResult()).toList();

    final updatedResults = <WebSearchResult>[];
    int insertedAt = 0;
    for (final r in state.results) {
      if (r.sourceUrl == original.sourceUrl) {
        insertedAt = updatedResults.length;
        updatedResults.addAll(newCards);
      } else {
        updatedResults.add(r);
      }
    }

    state = state.copyWith(results: updatedResults);

    // If the page is still resolving, poll so the cards flip from "Extracting"
    // to ready (or "couldn't extract") in place.
    if (resolution.status != 'resolved' && resolution.status != 'failed') {
      unawaited(_pollMultiStatuses(resolution.multiId));
    }
    return insertedAt;
  }

  /// Polls the resolve endpoint and updates each expanded card's extraction
  /// status in place until the page finishes resolving (or a timeout).
  Future<void> _pollMultiStatuses(String multiId) async {
    final deadline = DateTime.now().add(const Duration(minutes: 2));
    while (mounted && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      final resolution = await _fetchResolution(multiId);
      if (resolution == null) continue;
      _applyCardStatuses(resolution);
      if (resolution.status == 'resolved' || resolution.status == 'failed') {
        break;
      }
    }
  }

  Future<MultiRecipeResolution?> _fetchResolution(String multiId) async {
    try {
      final response =
          await _apiClient.get(ApiEndpoints.resolveMultiRecipe(multiId));
      return MultiRecipeResolution.fromJson(
          response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Updates the extraction status of any expanded card (matched by title)
  /// from a fresh resolution snapshot. Plain search results (no status) are
  /// left untouched.
  void _applyCardStatuses(MultiRecipeResolution resolution) {
    final statusByTitle = <String, String>{
      for (final c in resolution.recipes) c.title: c.extractionStatus,
    };
    var changed = false;
    final updated = state.results.map((r) {
      if (r.extractionStatus == null) return r;
      final status = statusByTitle[r.title];
      if (status != null && status != r.extractionStatus) {
        changed = true;
        return r.copyWith(extractionStatus: status);
      }
      return r;
    }).toList();
    if (changed) {
      state = state.copyWith(results: updated);
    }
  }

  void clear() {
    _newRun();
    state = SearchState(
      agentMode: state.agentMode,
      facets: state.facets,
      viewMode: state.viewMode,
    );
  }
}

final searchSuggestionsProvider =
    FutureProvider.family<List<String>, String>((ref, query) async {
  if (query.length < 2) return [];

  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get(
    ApiEndpoints.search,
    queryParameters: {'q': query},
  );

  final data = response.data;
  if (data is List) {
    return data.map((e) => e.toString()).toList();
  }
  if (data is Map<String, dynamic> && data['suggestions'] is List) {
    return (data['suggestions'] as List).map((e) => e.toString()).toList();
  }
  return [];
});
