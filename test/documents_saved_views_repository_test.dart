import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';

void main() {
  group('DocumentsRepository.fetchSavedViews', () {
    test('parses paginated saved views from the Paperless API', () async {
      final dio = Dio();
      final adapter = _FakeHttpClientAdapter();
      dio.httpClientAdapter = adapter;

      adapter.enqueueJson(
        body: <String, Object?>{
          'count': 1,
          'results': <Object?>[
            <String, Object?>{
              'id': 42,
              'name': 'Inbox invoices',
              'sort_field': 'created',
              'sort_reverse': true,
              'page_size': 25,
              'filter_rules': <Object?>[
                <String, Object?>{'rule_type': 5, 'value': 'true'},
                <String, Object?>{'rule_type': 6, 'value': '12'},
              ],
            },
          ],
        },
      );

      final repository = DocumentsRepository(
        dio: dio,
        session: const PaperlessAuthSession(
          serverUrl: 'https://example.com/paperless/',
          username: 'jane',
          password: 'secret',
          authToken: 'token-123',
        ),
      );

      final savedViews = await repository.fetchSavedViews();

      expect(savedViews, hasLength(1));
      expect(savedViews.single.id, 42);
      expect(savedViews.single.name, 'Inbox invoices');
      expect(savedViews.single.sortField, 'created');
      expect(savedViews.single.sortReverse, isTrue);
      expect(savedViews.single.pageSize, 25);
      expect(savedViews.single.filterRules, hasLength(2));
      expect(savedViews.single.filterRules.first.ruleType, 5);
      expect(savedViews.single.filterRules.first.value, 'true');
      expect(savedViews.single.filterRules.last.ruleType, 6);
      expect(savedViews.single.filterRules.last.value, '12');

      expect(
        adapter.lastRequestOptions?.uri.toString(),
        'https://example.com/paperless/api/saved_views/?page=1&page_size=1000',
      );
      expect(
        adapter.lastRequestOptions?.headers['Authorization'],
        'Token token-123',
      );
    });
  });
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  final List<ResponseBody> _queuedResponses = <ResponseBody>[];

  RequestOptions? lastRequestOptions;

  void enqueueJson({required Map<String, Object?> body, int statusCode = 200}) {
    _queuedResponses.add(
      ResponseBody.fromBytes(
        utf8.encode(jsonEncode(body)),
        statusCode,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      ),
    );
  }

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions requestOptions,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = requestOptions;
    if (_queuedResponses.isEmpty) {
      throw StateError('No fake response enqueued.');
    }

    return _queuedResponses.removeAt(0);
  }
}
