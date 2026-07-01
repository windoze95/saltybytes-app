import '../core/providers/finder_provider.dart';
import '../core/providers/search_provider.dart';

/// A saved agent (finder) run — the intent that drove it, the resulting
/// shortlist (including any dug-in recipes), and the narration. Sessions are
/// auto-saved server-side; the app only lists / opens / deletes them.
///
/// List items and the detail endpoint share this shape.
class FinderSession {
  const FinderSession({
    required this.id,
    required this.title,
    required this.intent,
    this.results = const [],
    this.narration = const [],
    this.createdAt,
  });

  final int id;
  final String title;
  final FinderFacets intent;
  final List<WebSearchResult> results;
  final List<String> narration;
  final DateTime? createdAt;

  int get resultCount => results.length;

  /// The first result with an image — used as the row thumbnail.
  String? get thumbnailUrl {
    for (final r in results) {
      final url = r.imageUrl;
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  factory FinderSession.fromJson(Map<String, dynamic> json) {
    // Session `results` are flat SearchResult objects; wrap each as
    // {result: ...} so the shared folder handles rating-0 / empty-image
    // coercion (reason + safety are simply absent).
    final results = ((json['results'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((r) => webSearchResultFromFinderItem({'result': r}))
        .toList();

    return FinderSession(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Recipe search',
      intent: FinderFacets.fromJson(
          (json['intent'] as Map<String, dynamic>?) ?? const {}),
      results: results,
      narration: (json['narration'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}
