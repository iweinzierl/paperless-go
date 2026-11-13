import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_ngx_app/src/features/auth/data/repositories/auth_repository.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_method.dart';

void main() {
  group('normalizePaperlessBaseUrl', () {
    test('keeps a server subpath intact', () {
      final normalized = normalizePaperlessBaseUrl(
        'https://example.com/paperless',
      );

      expect(normalized, 'https://example.com/paperless/');
      expect(
        buildPaperlessApiBaseUri(normalized).toString(),
        'https://example.com/paperless/api/',
      );
    });

    test('accepts a URL that already points to /api', () {
      final normalized = normalizePaperlessBaseUrl(
        'https://example.com/paperless/api/',
      );

      expect(normalized, 'https://example.com/paperless/');
      expect(
        buildPaperlessApiBaseUri(normalized).toString(),
        'https://example.com/paperless/api/',
      );
    });
  });

  group('AuthRepository.signIn', () {
    Future<RequestOptions> signInAndCaptureTokenRequest({String? code}) async {
      final dio = Dio();
      final adapter = _FakeHttpClientAdapter();
      dio.httpClientAdapter = adapter;

      adapter.enqueueJson(body: <String, Object?>{'token': 'token-123'});
      adapter.enqueueJson(
        body: <String, Object?>{
          'username': 'u',
          'first_name': 'Jane',
          'last_name': 'Doe',
        },
      );

      final session = await AuthRepository(dio).signIn(
        serverUrl: 'https://example.com',
        username: 'u',
        password: 'p',
        code: code,
      );

      expect(session.authToken, 'token-123');
      return adapter.requests.first;
    }

    test('sends a trimmed MFA code with the token request', () async {
      final request = await signInAndCaptureTokenRequest(code: ' 123456 ');

      expect(request.method, 'POST');
      expect(request.uri.toString(), 'https://example.com/api/token/');
      expect(request.data, <String, dynamic>{
        'username': 'u',
        'password': 'p',
        'code': '123456',
      });
    });

    test('omits the code when none is given', () async {
      final request = await signInAndCaptureTokenRequest();

      expect(request.data, <String, dynamic>{'username': 'u', 'password': 'p'});
    });

    test('omits the code when it is empty', () async {
      final request = await signInAndCaptureTokenRequest(code: '');

      expect(request.data, <String, dynamic>{'username': 'u', 'password': 'p'});
    });
  });

  group('AuthRepository.signInWithToken', () {
    test('validates the token against the profile endpoint only', () async {
      final dio = Dio();
      final adapter = _FakeHttpClientAdapter();
      dio.httpClientAdapter = adapter;

      adapter.enqueueJson(
        body: <String, Object?>{
          'username': 'jane.doe',
          'first_name': 'Jane',
          'last_name': 'Doe',
        },
      );

      final session = await AuthRepository(dio).signInWithToken(
        serverUrl: 'https://example.com/paperless',
        token: 'token-123',
      );

      expect(adapter.requests, hasLength(1));
      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(
        request.uri.toString(),
        'https://example.com/paperless/api/profile/',
      );
      expect(request.headers['Authorization'], 'Token token-123');
      expect(session.serverUrl, 'https://example.com/paperless/');
      expect(session.authToken, 'token-123');
      expect(session.username, 'jane.doe');
      expect(session.password, isEmpty);
      expect(session.displayName, 'Jane Doe');
      expect(session.method, PaperlessAuthMethod.token);
    });

    test('maps a 401 without detail to authenticationFailed', () async {
      final dio = Dio();
      final adapter = _FakeHttpClientAdapter();
      dio.httpClientAdapter = adapter;

      adapter.enqueueJson(body: <String, Object?>{}, statusCode: 401);

      await expectLater(
        AuthRepository(
          dio,
        ).signInWithToken(serverUrl: 'https://example.com', token: 'invalid'),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.code,
            'code',
            AuthFailureCode.authenticationFailed,
          ),
        ),
      );
    });

    test('maps a connection error to unableToReachServer', () async {
      final dio = Dio();
      final adapter = _FakeHttpClientAdapter();
      dio.httpClientAdapter = adapter;

      adapter.enqueueError(
        (requestOptions) => DioException.connectionError(
          requestOptions: requestOptions,
          reason: 'Connection refused',
        ),
      );

      await expectLater(
        AuthRepository(
          dio,
        ).signInWithToken(serverUrl: 'https://example.com', token: 'token-123'),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.code,
            'code',
            AuthFailureCode.unableToReachServer,
          ),
        ),
      );
    });
  });
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  final List<Object> _queuedResponses = <Object>[];

  final List<RequestOptions> requests = <RequestOptions>[];

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

  void enqueueError(
    DioException Function(RequestOptions requestOptions) errorBuilder,
  ) {
    _queuedResponses.add(errorBuilder);
  }

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions requestOptions,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(requestOptions);
    if (_queuedResponses.isEmpty) {
      throw StateError('No fake response enqueued.');
    }

    final next = _queuedResponses.removeAt(0);
    if (next is DioException Function(RequestOptions)) {
      throw next(requestOptions);
    }

    return next as ResponseBody;
  }
}
