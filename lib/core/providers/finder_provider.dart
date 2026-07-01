import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/allergen.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'search_provider.dart';

// ---------------------------------------------------------------------------
// Request models
// ---------------------------------------------------------------------------

/// The tap-first choices from the finder mood screen. Immutable; the mood
/// screen builds one and hands it to the run screen via GoRouter `extra`.
///
/// Single-select facets are nullable (null = not chosen); "use what I have" is
/// a free list of ingredient chips; "surprise me" relaxes everything. Mirrors
/// the backend `FinderFacets` (snake_case, omitempty).
class FinderFacets {
  const FinderFacets({
    this.occasion,
    this.timeBudget,
    this.protein,
    this.cuisine,
    this.useWhatIHave = const [],
    this.surpriseMe = false,
    this.freeText,
  });

  final String? occasion;
  final String? timeBudget;
  final String? protein;
  final String? cuisine;
  final List<String> useWhatIHave;
  final bool surpriseMe;

  /// Optional typed/spoken details (second-class to the chips).
  final String? freeText;

  /// The `facets` object of the request body.
  Map<String, dynamic> toFacetsJson() => {
        if (occasion != null) 'occasion': occasion,
        if (timeBudget != null) 'time_budget': timeBudget,
        if (protein != null) 'protein': protein,
        if (cuisine != null) 'cuisine': cuisine,
        'use_what_i_have': useWhatIHave,
        'surprise_me': surpriseMe,
      };

  /// The full `POST /v1/recipes/find` body, optionally carrying a [refine].
  Map<String, dynamic> toRequestJson({FinderRefine? refine}) {
    final text = freeText?.trim();
    return {
      'facets': toFacetsJson(),
      if (text != null && text.isNotEmpty) 'free_text': text,
      if (refine != null) 'refine': refine.toJson(),
    };
  }
}

/// A tap-to-refine follow-up ("quicker", "cheaper", …). Sent as the request's
/// `refine` field so the backend re-runs the bounded flow with the constraint.
class FinderRefine {
  const FinderRefine({this.addFacets, required this.constraint});

  final FinderFacets? addFacets;
  final String constraint;

  Map<String, dynamic> toJson() => {
        'add_facets': (addFacets ?? const FinderFacets()).toFacetsJson(),
        'constraint': constraint,
      };
}

// ---------------------------------------------------------------------------
// SSE event models
// ---------------------------------------------------------------------------

/// One ranked shortlist entry: a real search result, a one-line rationale and
/// per-member safety badges. Mirrors the backend `FinderResultItem`.
///
/// The nested `SearchResult` (title/source/rating/image/description — no cook
/// time, no safety) plus the sibling `safety[]` are folded into a single
/// [WebSearchResult] so the existing result card + preview/import flow can be
/// reused verbatim; [reason] is surfaced as the card's one-line subtitle.
class FinderResultItem {
  const FinderResultItem({
    required this.result,
    this.reason,
    this.safety = const [],
  });

  final WebSearchResult result;
  final String? reason;
  final List<FamilySafetyCheck> safety;

  factory FinderResultItem.fromJson(Map<String, dynamic> json) {
    final resultJson =
        (json['result'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    final safety = ((json['safety'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_memberSafetyToCheck)
        .toList();

    // rating is a non-omitempty float on the wire (0.0 when the source has no
    // rating) — treat non-positive as "no rating" so the card shows no stars.
    final rating = (resultJson['rating'] as num?)?.toDouble();
    final imageUrl = resultJson['image_url'] as String?;

    final result = WebSearchResult(
      title: resultJson['title'] as String? ?? 'Untitled',
      sourceUrl: resultJson['source_url'] as String?,
      sourceDomain: resultJson['source_domain'] as String?,
      imageUrl: (imageUrl == null || imageUrl.isEmpty) ? null : imageUrl,
      description: resultJson['description'] as String?,
      rating: (rating != null && rating > 0) ? rating : null,
      familySafetyChecks: safety,
    );

    final reason = (json['reason'] as String?)?.trim();
    return FinderResultItem(
      result: result,
      reason: (reason == null || reason.isEmpty) ? null : reason,
      safety: safety,
    );
  }
}

/// Maps a backend `MemberSafety` ({member_name, status, note}) onto the app's
/// existing [FamilySafetyCheck] so the shared safety-badge UI lights up.
FamilySafetyCheck _memberSafetyToCheck(Map<String, dynamic> json) {
  final note = json['note'] as String?;
  return FamilySafetyCheck(
    memberName: json['member_name'] as String? ?? '',
    status: json['status'] as String? ?? 'safe',
    warnings: (note != null && note.isNotEmpty) ? [note] : const [],
  );
}

/// A single decoded SSE event. Flat + omitempty, mirroring the backend
/// `FinderEvent`; [type] is always present and drives the UI transition.
class FinderEvent {
  const FinderEvent({
    required this.type,
    this.query,
    this.count,
    this.fromCache = false,
    this.items = const [],
    this.urls = const [],
    this.chips = const [],
    this.broaden = const [],
    this.error,
  });

  final String type;
  final String? query;
  final int? count;
  final bool fromCache;
  final List<FinderResultItem> items;
  final List<String> urls;
  final List<String> chips;
  final List<String> broaden;
  final String? error;

  factory FinderEvent.fromJson(Map<String, dynamic> json, {String? fallbackType}) {
    List<String> strList(dynamic v) =>
        (v as List?)?.map((e) => e.toString()).toList() ?? const [];
    return FinderEvent(
      type: json['type'] as String? ?? fallbackType ?? '',
      query: json['query'] as String?,
      count: (json['count'] as num?)?.toInt(),
      fromCache: json['from_cache'] as bool? ?? false,
      items: ((json['items'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(FinderResultItem.fromJson)
          .toList(),
      urls: strList(json['urls']),
      chips: strList(json['chips']),
      broaden: strList(json['broaden']),
      error: json['error'] as String?,
    );
  }
}

/// Parses a raw SSE byte stream into [FinderEvent]s.
///
/// Pure and unit-testable: pass any `Stream<List<int>>` (e.g. the dio
/// `ResponseBody.stream`). The `utf8.decoder`/`LineSplitter` transformers are
/// stateful across chunks, so frames split mid-line between byte chunks are
/// reassembled correctly. `data:` lines accumulate until a blank line, then the
/// joined payload is JSON-decoded (its `type` field wins, falling back to the
/// `event:` line).
Stream<FinderEvent> parseFinderSse(Stream<List<int>> byteStream) async* {
  final dataLines = <String>[];
  String? eventName;

  await for (final line
      in byteStream.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.isEmpty) {
      final event = _frameToEvent(eventName, dataLines);
      if (event != null) yield event;
      dataLines.clear();
      eventName = null;
      continue;
    }
    if (line.startsWith(':')) continue; // comment / heartbeat

    final colon = line.indexOf(':');
    final field = colon == -1 ? line : line.substring(0, colon);
    var value = colon == -1 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1); // optional space

    switch (field) {
      case 'event':
        eventName = value;
      case 'data':
        dataLines.add(value);
      // id / retry ignored
    }
  }

  // Flush a trailing frame that arrived without a terminating blank line.
  final event = _frameToEvent(eventName, dataLines);
  if (event != null) yield event;
}

FinderEvent? _frameToEvent(String? eventName, List<String> dataLines) {
  if (dataLines.isEmpty) {
    return eventName == null ? null : FinderEvent(type: eventName);
  }
  final payload = dataLines.join('\n').trim();
  if (payload.isEmpty) {
    return eventName == null ? null : FinderEvent(type: eventName);
  }
  try {
    final json = jsonDecode(payload) as Map<String, dynamic>;
    return FinderEvent.fromJson(json, fallbackType: eventName);
  } catch (_) {
    return null; // ignore a malformed frame rather than tear down the stream
  }
}

// ---------------------------------------------------------------------------
// Run state
// ---------------------------------------------------------------------------

/// Where a finder run is in its bounded trajectory. Terminal: done / empty /
/// error.
enum FinderPhase {
  idle,
  searching,
  found,
  filtering,
  shortlist,
  warming,
  refineReady,
  done,
  empty,
  error,
}

/// The live state of a finder run, shaped like `SearchState`: the current
/// [phase], the growing [narration] strip, the ranked [items] shortlist,
/// tap-to-[refineChips], [broaden] suggestions for the empty path, plus
/// [error]/[isLimitReached] for the failure/quota states.
class FinderRunState {
  const FinderRunState({
    this.phase = FinderPhase.idle,
    this.narration = const [],
    this.items = const [],
    this.refineChips = const [],
    this.broaden = const [],
    this.query,
    this.error,
    this.isLimitReached = false,
    this.isRefining = false,
  });

  final FinderPhase phase;
  final List<String> narration;
  final List<FinderResultItem> items;
  final List<String> refineChips;
  final List<String> broaden;
  final String? query;
  final String? error;
  final bool isLimitReached;
  final bool isRefining;

  /// The run reached a terminal event.
  bool get isDone =>
      phase == FinderPhase.done ||
      phase == FinderPhase.empty ||
      phase == FinderPhase.error;

  /// The run is mid-flight (streaming), so the narration strip should show a
  /// live "working" spinner.
  bool get isActive => phase != FinderPhase.idle && !isDone;

  bool get isEmpty => phase == FinderPhase.empty;
  bool get hasItems => items.isNotEmpty;

  FinderRunState copyWith({
    FinderPhase? phase,
    List<String>? narration,
    List<FinderResultItem>? items,
    List<String>? refineChips,
    List<String>? broaden,
    String? query,
    String? error,
    bool? isLimitReached,
    bool? isRefining,
  }) {
    return FinderRunState(
      phase: phase ?? this.phase,
      narration: narration ?? this.narration,
      items: items ?? this.items,
      refineChips: refineChips ?? this.refineChips,
      broaden: broaden ?? this.broaden,
      query: query ?? this.query,
      // Cleared unless explicitly provided (matches SearchState's idiom); the
      // error phase is terminal so nothing copies over it.
      error: error,
      isLimitReached: isLimitReached ?? this.isLimitReached,
      isRefining: isRefining ?? this.isRefining,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

final finderProvider =
    StateNotifierProvider<FinderNotifier, FinderRunState>((ref) {
  return FinderNotifier(apiClient: ref.watch(apiClientProvider));
});

class FinderNotifier extends StateNotifier<FinderRunState> {
  FinderNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const FinderRunState());

  final ApiClient _apiClient;

  /// The facets of the current run, reused as the base for refinements.
  FinderFacets? _lastFacets;

  /// Kicks off a finder run for [facets]. Streams the SSE trajectory into
  /// [state].
  Future<void> run(FinderFacets facets) async {
    _lastFacets = facets;
    state = const FinderRunState(phase: FinderPhase.searching);
    await _stream(facets.toRequestJson());
  }

  /// Re-runs the last facets with an added [constraint] (a refine chip like
  /// "quicker"). No-op if there's no prior run.
  Future<void> refine(String constraint) async {
    final base = _lastFacets;
    if (base == null) return;
    state = FinderRunState(
      phase: FinderPhase.searching,
      isRefining: true,
      narration: ['Refining: $constraint…'],
    );
    await _stream(base.toRequestJson(refine: FinderRefine(constraint: constraint)));
  }

  Future<void> _stream(Map<String, dynamic> body) async {
    try {
      final resp = await _apiClient.dio.post(
        ApiEndpoints.find,
        data: body,
        options: Options(
          responseType: ResponseType.stream,
          // The stream can run well past the 15s global receive timeout.
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      final stream = (resp.data as ResponseBody).stream.cast<List<int>>();
      await for (final event in parseFinderSse(stream)) {
        if (!mounted) return;
        _applyEvent(event);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      _applyDioError(e);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        phase: FinderPhase.error,
        error: 'Something went wrong finding recipes. Please try again.',
      );
    }
  }

  void _applyDioError(DioException e) {
    if (e.response?.statusCode == 403) {
      state = state.copyWith(
        phase: FinderPhase.error,
        isLimitReached: true,
        error: 'You’ve reached your search limit. Upgrade to Premium for '
            'unlimited recipe finds.',
      );
      return;
    }
    state = state.copyWith(
      phase: FinderPhase.error,
      error: userFacingErrorMessage(
          e, 'Something went wrong finding recipes. Please try again.'),
    );
  }

  void _applyEvent(FinderEvent e) {
    switch (e.type) {
      case 'searching':
        final q = (e.query ?? '').trim();
        state = state.copyWith(
          phase: FinderPhase.searching,
          query: q.isEmpty ? null : q,
          narration: [
            ...state.narration,
            q.isEmpty ? '\u{1F50D} Searching for recipes…' : '\u{1F50D} Searching “$q”…',
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
      case 'filtering':
        state = state.copyWith(
          phase: FinderPhase.filtering,
          narration: [...state.narration, 'Checking these against your family…'],
        );
      case 'shortlist':
        state = state.copyWith(
          phase: FinderPhase.shortlist,
          items: e.items,
        );
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
          isRefining: false,
        );
      case 'done':
        state = state.copyWith(phase: FinderPhase.done, isRefining: false);
      case 'empty':
        state = state.copyWith(
          phase: FinderPhase.empty,
          items: const [],
          broaden: e.broaden,
          isRefining: false,
        );
      case 'error':
        state = state.copyWith(
          phase: FinderPhase.error,
          error: (e.error == null || e.error!.isEmpty)
              ? 'Something went wrong finding recipes. Please try again.'
              : e.error,
          isRefining: false,
        );
    }
  }
}
