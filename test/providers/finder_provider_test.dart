import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:saltybytes_app/core/providers/finder_provider.dart';

/// Builds one SSE frame exactly as the backend emits it: an `event:` line, a
/// `data:` line carrying the JSON (which itself has a `type`), and a blank
/// terminator line.
String _frame(String type, Map<String, dynamic> data) {
  final payload = jsonEncode({'type': type, ...data});
  return 'event: $type\ndata: $payload\n\n';
}

/// Turns an SSE string into a byte stream chopped into [size]-byte chunks, so
/// frames are split mid-line (and mid-JSON) across chunk boundaries — the
/// realistic case the parser must reassemble.
Stream<List<int>> _chunked(String sse, {int size = 7}) {
  final bytes = utf8.encode(sse);
  return Stream.fromIterable([
    for (var i = 0; i < bytes.length; i += size)
      bytes.sublist(i, (i + size) > bytes.length ? bytes.length : i + size),
  ]);
}

void main() {
  group('parseFinderSse', () {
    test('reassembles a happy-path sequence split mid-line into events',
        () async {
      final sse = [
        _frame('searching', {'query': 'chicken pasta'}),
        _frame('found', {'count': 8, 'from_cache': false}),
        _frame('filtering', {}),
        _frame('shortlist', {
          'items': [
            {
              'result': {
                'title': 'Creamy Chicken Pasta',
                'source_url': 'https://example.com/ccp',
                'source_domain': 'example.com',
                'rating': 4.6,
                'image_url': '',
                'description': 'Weeknight chicken pasta',
              },
              'reason': 'Quick and kid-friendly',
              'safety': [
                {
                  'member_name': 'Junior',
                  'status': 'avoid',
                  'note': 'contains peanuts',
                },
              ],
            },
          ],
        }),
        _frame('warming', {
          'urls': ['https://example.com/ccp'],
        }),
        _frame('refine_ready', {
          'chips': ['quicker', 'cheaper', 'more veg', 'swap protein'],
          'broaden': <String>[],
        }),
        _frame('done', {}),
      ].join();

      // A deliberately tiny chunk size guarantees frames are cut mid-line.
      final events = await parseFinderSse(_chunked(sse, size: 5)).toList();

      expect(events.map((e) => e.type).toList(), [
        'searching',
        'found',
        'filtering',
        'shortlist',
        'warming',
        'refine_ready',
        'done',
      ]);

      expect(events[0].query, 'chicken pasta');
      expect(events[1].count, 8);
      expect(events[1].fromCache, isFalse);

      final shortlist = events[3];
      expect(shortlist.items, hasLength(1));
      final item = shortlist.items.first;
      expect(item.result.title, 'Creamy Chicken Pasta');
      expect(item.result.sourceDomain, 'example.com');
      expect(item.result.rating, 4.6);
      // image_url "" coerces to null so the card falls back to a placeholder.
      expect(item.result.imageUrl, isNull);
      expect(item.reason, 'Quick and kid-friendly');
      // MemberSafety folds into the existing FamilySafetyCheck (avoid = unsafe)
      // and also lands on the result so the card's safety UI lights up.
      expect(item.safety, hasLength(1));
      expect(item.safety.first.memberName, 'Junior');
      expect(item.safety.first.status, 'avoid');
      expect(item.safety.first.isSafe, isFalse);
      expect(item.result.familySafetyChecks, hasLength(1));

      expect(events[5].chips,
          ['quicker', 'cheaper', 'more veg', 'swap protein']);
    });

    test('treats a non-positive rating as "no rating"', () async {
      final sse = _frame('shortlist', {
        'items': [
          {
            'result': {
              'title': 'No Rating Recipe',
              'source_url': 'https://example.com/x',
              'rating': 0.0, // wire default when the source has no rating
              'image_url': '',
            },
          },
        ],
      });

      final events = await parseFinderSse(_chunked(sse)).toList();
      expect(events, hasLength(1));
      expect(events.first.items.first.result.rating, isNull);
      expect(events.first.items.first.reason, isNull);
    });

    test('parses the terminal empty path (searching → found → empty)',
        () async {
      final sse = [
        _frame('searching', {'query': 'ghost pepper cereal'}),
        _frame('found', {'count': 0}),
        _frame('empty', {
          'broaden': ['comfort food', 'quick dinners'],
        }),
      ].join();

      final events = await parseFinderSse(_chunked(sse, size: 3)).toList();
      expect(events.map((e) => e.type).toList(),
          ['searching', 'found', 'empty']);
      expect(events.last.broaden, ['comfort food', 'quick dinners']);
    });

    test('carries an error payload through', () async {
      final sse = _frame('error', {'error': 'search failed'});
      final events = await parseFinderSse(_chunked(sse)).toList();
      expect(events, hasLength(1));
      expect(events.first.type, 'error');
      expect(events.first.error, 'search failed');
    });

    test('falls back to the event: name when the data JSON has no type',
        () async {
      // A frame whose JSON omits "type" — the parser should use the event line.
      const sse = 'event: filtering\ndata: {}\n\n';
      final events = await parseFinderSse(_chunked(sse, size: 4)).toList();
      expect(events, hasLength(1));
      expect(events.first.type, 'filtering');
    });

    test('flushes a trailing frame that lacks a terminating blank line',
        () async {
      final sse = _frame('searching', {'query': 'x'}).trimRight();
      final events = await parseFinderSse(_chunked(sse)).toList();
      expect(events, hasLength(1));
      expect(events.first.type, 'searching');
      expect(events.first.query, 'x');
    });
  });
}
