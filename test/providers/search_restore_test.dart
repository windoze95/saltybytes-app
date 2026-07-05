import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/finder_provider.dart';
import 'package:saltybytes_app/core/providers/search_provider.dart';
import 'package:saltybytes_app/models/finder_session.dart';

import '../helpers/test_helpers.dart';

Map<String, dynamic> _sessionJson({
  int id = 12,
  List<Map<String, dynamic>>? results,
}) =>
    {
      'id': id,
      'title': 'chicken dinner',
      'created_at': '2026-07-01T10:00:00Z',
      'intent': {
        'cuisine': 'Italian',
        'protein': 'chicken',
        'occasion': '',
        'use_what_i_have': ['spinach'],
        'surprise_me': false,
        'free_text': 'cozy',
      },
      'results': results ??
          [
            {'title': 'A', 'source_url': 'https://x.com/a', 'image_url': ''},
            {'title': 'B', 'source_url': 'https://x.com/b', 'rating': 0.0},
          ],
      'narration': ['Searched for chicken', 'Found 2 recipes'],
    };

String _frame(String type, Map<String, dynamic> data) =>
    'event: $type\ndata: ${jsonEncode({'type': type, ...data})}\n\n';

Response<dynamic> _sse(String body) => Response<dynamic>(
      data: ResponseBody(
        Stream.fromIterable([Uint8List.fromList(utf8.encode(body))]),
        200,
        headers: {
          Headers.contentTypeHeader: ['text/event-stream']
        },
      ),
      statusCode: 200,
      requestOptions: RequestOptions(path: ApiEndpoints.find),
    );

void main() {
  group('FinderFacets.fromJson', () {
    test('parses the intent wire shape (empty strings → null)', () {
      final f = FinderFacets.fromJson({
        'cuisine': 'Italian',
        'protein': 'chicken',
        'occasion': '',
        'use_what_i_have': ['spinach', 'garlic'],
        'surprise_me': true,
        'free_text': 'cozy',
      });
      expect(f.cuisine, 'Italian');
      expect(f.protein, 'chicken');
      expect(f.occasion, isNull); // empty string coerces to null
      expect(f.useWhatIHave, ['spinach', 'garlic']);
      expect(f.surpriseMe, isTrue);
      expect(f.freeText, 'cozy');
    });
  });

  group('FinderSession.fromJson', () {
    test('parses flat SearchResult results + intent + narration', () {
      final s = FinderSession.fromJson(_sessionJson());
      expect(s.id, 12);
      expect(s.title, 'chicken dinner');
      expect(s.intent.cuisine, 'Italian');
      expect(s.results.map((r) => r.title).toList(), ['A', 'B']);
      // rating 0.0 folds to null (via webSearchResultFromFinderItem).
      expect(s.results[1].rating, isNull);
      expect(s.narration, ['Searched for chicken', 'Found 2 recipes']);
      expect(s.resultCount, 2);
    });
  });

  group('restoreFromSession', () {
    test('repopulates SearchState as a finished agent run (no re-run)', () {
      final container = ProviderContainer(
          overrides: [apiClientProvider.overrideWithValue(MockApiClient())]);
      addTearDown(container.dispose);
      final notifier = container.read(searchProvider.notifier);

      notifier.restoreFromSession(FinderSession.fromJson(_sessionJson()));

      final state = container.read(searchProvider);
      expect(state.agentMode, isTrue);
      expect(state.hasSearched, isTrue);
      expect(state.phase, FinderPhase.done);
      expect(state.hasMore, isFalse);
      expect(state.results.map((r) => r.title).toList(), ['A', 'B']);
      expect(state.nextOffset, 2);
      // toKeywordQuery order: cuisine, protein, occasion, time, ingredients, free.
      expect(state.query, 'Italian chicken spinach cozy');
      expect(state.narration, ['Searched for chicken', 'Found 2 recipes']);
      expect(state.facets.cuisine, 'Italian');
    });
  });

  group('agent digging + expanded (SSE)', () {
    test('digging narrates and expanded folds recipes into the results',
        () async {
      final apiClient = MockApiClient();
      final dio = MockDio();
      when(() => apiClient.dio).thenReturn(dio);
      when(() => apiClient.post(ApiEndpoints.warmUrls, data: any(named: 'data')))
          .thenAnswer((_) async => fakeResponse<dynamic>({'statuses': {}}));
      when(() => dio.post(ApiEndpoints.find,
          data: any(named: 'data'),
          cancelToken: any(named: 'cancelToken'),
          options: any(named: 'options'))).thenAnswer((_) async => _sse([
            _frame('shortlist', {
              'items': [
                {
                  'result': {
                    'title': 'Base',
                    'source_url': 'https://x.com/base',
                    'image_url': ''
                  }
                }
              ],
              'has_more': false,
            }),
            _frame('digging', {'collection_title': '23 Best Weeknight Dinners'}),
            _frame('expanded', {
              'collection_title': '23 Best Weeknight Dinners',
              'items': [
                {
                  'result': {
                    'title': 'Dug One',
                    'source_url': 'https://x.com/dug1',
                    'image_url': ''
                  },
                  'reason': "from '23 Best Weeknight Dinners'",
                }
              ],
            }),
            _frame('done', {}),
          ].join()));

      final container = ProviderContainer(
          overrides: [apiClientProvider.overrideWithValue(apiClient)]);
      addTearDown(container.dispose);
      final notifier = container.read(searchProvider.notifier);

      await notifier.search();

      final state = container.read(searchProvider);
      expect(state.results.map((r) => r.title).toList(), ['Base', 'Dug One']);
      expect(state.results[1].reason, contains('23 Best Weeknight Dinners'));
      expect(
        state.narration.any((l) => l.contains('23 Best Weeknight Dinners')),
        isTrue,
      );
    });
  });
}
