import 'dart:convert';

import '../../models/allergen.dart';
import 'search_provider.dart';

// ---------------------------------------------------------------------------
// Finder helpers
//
// The finder is no longer a separate feature/provider — it's the "agent" mode
// of Search (see SearchNotifier/SearchState in search_provider.dart). This file
// keeps the pure, reusable finder pieces: the facet model, the SSE event model
// + parser, and the run phases.
// ---------------------------------------------------------------------------

/// The tap-first facet choices that drive an agent search. Immutable.
///
/// Single-select facets are nullable (null = not chosen); "use what I have" is
/// a free list of ingredient chips; "surprise me" relaxes everything;
/// [freeText] is the optional typed/spoken details. Mirrors the backend
/// `FinderFacets` (snake_case, omitempty).
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
  final String? freeText;

  /// Number of set facets (beyond free text) — used to badge "Filters (n)".
  int get selectedCount =>
      [occasion, timeBudget, protein, cuisine].where((f) => f != null).length +
      useWhatIHave.length +
      (surpriseMe ? 1 : 0);

  bool get isEmpty =>
      selectedCount == 0 && (freeText?.trim().isEmpty ?? true);

  static const Object _sentinel = Object();

  /// copyWith that can also CLEAR a nullable single-select (pass an explicit
  /// null); omitting a field leaves it unchanged.
  FinderFacets copyWith({
    Object? occasion = _sentinel,
    Object? timeBudget = _sentinel,
    Object? protein = _sentinel,
    Object? cuisine = _sentinel,
    List<String>? useWhatIHave,
    bool? surpriseMe,
    Object? freeText = _sentinel,
  }) {
    return FinderFacets(
      occasion: occasion == _sentinel ? this.occasion : occasion as String?,
      timeBudget:
          timeBudget == _sentinel ? this.timeBudget : timeBudget as String?,
      protein: protein == _sentinel ? this.protein : protein as String?,
      cuisine: cuisine == _sentinel ? this.cuisine : cuisine as String?,
      useWhatIHave: useWhatIHave ?? this.useWhatIHave,
      surpriseMe: surpriseMe ?? this.surpriseMe,
      freeText: freeText == _sentinel ? this.freeText : freeText as String?,
    );
  }

  /// The `facets` object of the `POST /v1/recipes/find` body.
  Map<String, dynamic> toFacetsJson() => {
        if (occasion != null) 'occasion': occasion,
        if (timeBudget != null) 'time_budget': timeBudget,
        if (protein != null) 'protein': protein,
        if (cuisine != null) 'cuisine': cuisine,
        'use_what_i_have': useWhatIHave,
        'surprise_me': surpriseMe,
      };

  /// The full agent request body, optionally carrying a [refine] and a paging
  /// [offset] (Phase 1 pagination contract).
  Map<String, dynamic> toRequestJson({FinderRefine? refine, int? offset}) {
    final text = freeText?.trim();
    return {
      'facets': toFacetsJson(),
      if (text != null && text.isNotEmpty) 'free_text': text,
      if (refine != null) 'refine': refine.toJson(),
      if (offset != null && offset > 0) 'offset': offset,
    };
  }

  /// Flattens the facets into a plain keyword query for non-agent (plain)
  /// search, in the SAME order the backend's composeFinderQuery uses
  /// (cuisine, protein, occasion, time, ingredients, free text) — minus the
  /// allergen negations, which only the agent path applies server-side.
  String toKeywordQuery() {
    final text = freeText?.trim();
    final parts = <String>[
      if (cuisine != null && cuisine!.isNotEmpty) cuisine!,
      if (protein != null && protein!.isNotEmpty) protein!,
      if (occasion != null && occasion!.isNotEmpty) occasion!,
      if (timeBudget != null && timeBudget!.isNotEmpty) timeBudget!,
      for (final i in useWhatIHave)
        if (i.trim().isNotEmpty) i.trim(),
      if (text != null && text.isNotEmpty) text,
    ];
    return parts.join(' ').trim();
  }
}

/// A tap-to-refine follow-up ("quicker", "cheaper", …) sent as the request's
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

/// Where an agent run is in its bounded trajectory. Terminal: done/empty/error.
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

/// A single decoded SSE event from `POST /v1/recipes/find`. Flat + omitempty,
/// mirroring the backend `FinderEvent`; [type] is always present.
///
/// Shortlist [items] are folded straight into [WebSearchResult]s (the sibling
/// `reason` + `safety[]` are merged onto each result) so the whole app shares
/// one result type + card + preview/import flow.
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
    this.hasMore,
    this.error,
  });

  final String type;
  final String? query;
  final int? count;
  final bool fromCache;
  final List<WebSearchResult> items;
  final List<String> urls;
  final List<String> chips;
  final List<String> broaden;

  /// Whether more shortlist pages exist (Phase 1 pagination; carried on the
  /// `shortlist` event as `has_more`). Null when the backend omits it.
  final bool? hasMore;
  final String? error;

  factory FinderEvent.fromJson(Map<String, dynamic> json,
      {String? fallbackType}) {
    List<String> strList(dynamic v) =>
        (v as List?)?.map((e) => e.toString()).toList() ?? const [];
    return FinderEvent(
      type: json['type'] as String? ?? fallbackType ?? '',
      query: json['query'] as String?,
      count: (json['count'] as num?)?.toInt(),
      fromCache: json['from_cache'] as bool? ?? false,
      items: ((json['items'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(webSearchResultFromFinderItem)
          .toList(),
      urls: strList(json['urls']),
      chips: strList(json['chips']),
      broaden: strList(json['broaden']),
      hasMore: json['has_more'] as bool?,
      error: json['error'] as String?,
    );
  }
}

/// Folds a backend `FinderResultItem` ({result, reason, safety[]}) into a
/// [WebSearchResult]: rating 0.0 → null, image_url "" → null, `reason` attached,
/// and `MemberSafety[]` mapped onto `familySafetyChecks` so the shared card's
/// safety UI lights up.
WebSearchResult webSearchResultFromFinderItem(Map<String, dynamic> json) {
  final resultJson =
      (json['result'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

  final safety = ((json['safety'] as List?) ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(_memberSafetyToCheck)
      .toList();

  final rating = (resultJson['rating'] as num?)?.toDouble();
  final imageUrl = resultJson['image_url'] as String?;
  final reason = (json['reason'] as String?)?.trim();

  return WebSearchResult(
    title: resultJson['title'] as String? ?? 'Untitled',
    sourceUrl: resultJson['source_url'] as String?,
    sourceDomain: resultJson['source_domain'] as String?,
    imageUrl: (imageUrl == null || imageUrl.isEmpty) ? null : imageUrl,
    description: resultJson['description'] as String?,
    rating: (rating != null && rating > 0) ? rating : null,
    familySafetyChecks: safety,
    reason: (reason == null || reason.isEmpty) ? null : reason,
  );
}

/// Maps a backend `MemberSafety` ({member_name, status, note}) onto the app's
/// existing [FamilySafetyCheck] so the shared safety UI lights up.
FamilySafetyCheck _memberSafetyToCheck(Map<String, dynamic> json) {
  final note = json['note'] as String?;
  return FamilySafetyCheck(
    memberName: json['member_name'] as String? ?? '',
    status: json['status'] as String? ?? 'safe',
    warnings: (note != null && note.isNotEmpty) ? [note] : const [],
  );
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
