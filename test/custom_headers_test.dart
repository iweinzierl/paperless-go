import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_ngx_app/src/core/network/dio_provider.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/connection_secrets_storage.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/custom_headers.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/login_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const serviceTokenHeaders = <String, String>{
    'CF-Access-Client-Id': 'client-id.access',
    'CF-Access-Client-Secret': 'client-secret',
  };

  group('parseCustomHeaders', () {
    test('parses one header per line and skips blank lines', () {
      final headers = parseCustomHeaders(
        ' CF-Access-Client-Id : client-id.access \n\n'
        'CF-Access-Client-Secret: client-secret\r\n',
      );

      expect(headers, serviceTokenHeaders);
    });

    test('keeps colons inside the value', () {
      expect(parseCustomHeaders('X-Origin: https://example.com:8443'), {
        'X-Origin': 'https://example.com:8443',
      });
    });

    test('returns an empty map for empty text', () {
      expect(parseCustomHeaders(''), isEmpty);
      expect(parseCustomHeaders('  \n '), isEmpty);
    });

    test('rejects lines that are not a header', () {
      expect(parseCustomHeaders('no separator'), isNull);
      expect(parseCustomHeaders(': value'), isNull);
      expect(parseCustomHeaders('X-Empty:'), isNull);
      expect(parseCustomHeaders('Bad Name: value'), isNull);
      expect(parseCustomHeaders('X-Ok: value\nbroken'), isNull);
    });

    test('rejects values with control or non-ASCII characters', () {
      expect(parseCustomHeaders('X-Tab: a\tb'), isNull);
      expect(parseCustomHeaders('X-Null: a\x00b'), isNull);
      expect(parseCustomHeaders('X-Umlaut: wört'), isNull);
      expect(parseCustomHeaders('X-Return: a\rInjected: b'), isNull);
    });

    test('round-trips through formatCustomHeaders', () {
      final text = formatCustomHeaders(serviceTokenHeaders);

      expect(
        text,
        'CF-Access-Client-Id: client-id.access\n'
        'CF-Access-Client-Secret: client-secret',
      );
      expect(parseCustomHeaders(text), serviceTokenHeaders);
    });
  });

  group('CustomHeadersInterceptor', () {
    test('adds the custom headers but keeps the headers of the app', () async {
      var customHeaders = <String, String>{
        ...serviceTokenHeaders,
        'authorization': 'Bearer other',
      };
      final dio = Dio();
      final adapter = _FakeHttpClientAdapter();
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(CustomHeadersInterceptor(() => customHeaders));

      await dio.getUri(
        Uri.parse('https://example.com/api/profile/'),
        options: Options(
          headers: <String, Object>{'Authorization': 'Token token-123'},
        ),
      );

      final sentHeaders = adapter.lastRequestOptions!.headers;
      expect(sentHeaders['CF-Access-Client-Id'], 'client-id.access');
      expect(sentHeaders['CF-Access-Client-Secret'], 'client-secret');
      expect(sentHeaders['Authorization'], 'Token token-123');

      customHeaders = const <String, String>{};
      await dio.getUri(Uri.parse('https://example.com/api/profile/'));

      expect(
        adapter.lastRequestOptions!.headers.containsKey('CF-Access-Client-Id'),
        isFalse,
      );
    });

    test('leaves the custom headers out of plain HTTP requests', () async {
      final dio = Dio();
      final adapter = _FakeHttpClientAdapter();
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(CustomHeadersInterceptor(() => serviceTokenHeaders));

      await dio.getUri(Uri.parse('http://example.com/api/profile/'));

      final sentHeaders = adapter.lastRequestOptions!.headers;
      expect(sentHeaders.containsKey('CF-Access-Client-Id'), isFalse);
      expect(sentHeaders.containsKey('CF-Access-Client-Secret'), isFalse);
    });
  });

  group('DocumentsRepository.buildAuthenticatedHeaders', () {
    test('includes the custom headers for image and PDF requests', () {
      final repository = DocumentsRepository(
        dio: Dio(),
        session: const PaperlessAuthSession(
          serverUrl: 'https://example.com/',
          username: 'jane',
          password: 'secret',
          authToken: 'token-123',
        ),
        customHeaders: const <String, String>{
          ...serviceTokenHeaders,
          'authorization': 'Bearer other',
        },
      );

      expect(repository.buildAuthenticatedHeaders(), <String, String>{
        'Authorization': 'Token token-123',
        ...serviceTokenHeaders,
      });
    });

    test('leaves the custom headers out for a plain HTTP server', () {
      final repository = DocumentsRepository(
        dio: Dio(),
        session: const PaperlessAuthSession(
          serverUrl: 'http://example.com/',
          username: 'jane',
          password: 'secret',
          authToken: 'token-123',
        ),
        customHeaders: serviceTokenHeaders,
      );

      expect(repository.buildAuthenticatedHeaders(), <String, String>{
        'Authorization': 'Token token-123',
      });
    });
  });

  group('ConnectionSecretsStorage custom headers', () {
    const secureStorage = FlutterSecureStorage();

    test('writes, reloads and deletes the custom headers', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      SharedPreferences.setMockInitialValues(<String, Object>{
        'auth.server_url': 'https://example.com/',
      });
      final sharedPreferences = await SharedPreferences.getInstance();
      final storage = await ConnectionSecretsStorage.load(
        secureStorage,
        sharedPreferences,
      );

      expect(storage.customHeaders, isEmpty);

      await storage.writeCustomHeaders(serviceTokenHeaders);

      expect(storage.customHeaders, serviceTokenHeaders);
      expect(sharedPreferences.getKeys(), <String>{'auth.server_url'});

      final reloaded = await ConnectionSecretsStorage.load(
        secureStorage,
        sharedPreferences,
      );

      expect(reloaded.customHeaders, serviceTokenHeaders);

      await reloaded.writeCustomHeaders(const <String, String>{});

      expect(reloaded.customHeaders, isEmpty);
      expect(await secureStorage.read(key: 'auth.custom_headers'), isNull);
    });

    test('drops custom headers left over without a saved server', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'auth.custom_headers': jsonEncode(serviceTokenHeaders),
      });
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final sharedPreferences = await SharedPreferences.getInstance();

      final storage = await ConnectionSecretsStorage.load(
        secureStorage,
        sharedPreferences,
      );

      expect(storage.customHeaders, isEmpty);
      expect(await secureStorage.read(key: 'auth.custom_headers'), isNull);
    });

    test('ignores stored custom headers that cannot be decoded', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'auth.custom_headers': 'not json',
      });
      SharedPreferences.setMockInitialValues(<String, Object>{
        'auth.server_url': 'https://example.com/',
      });
      final sharedPreferences = await SharedPreferences.getInstance();

      final storage = await ConnectionSecretsStorage.load(
        secureStorage,
        sharedPreferences,
      );

      expect(storage.customHeaders, isEmpty);
    });
  });

  group('LoginFormState custom headers', () {
    const state = LoginFormState(
      serverUrl: 'https://example.com',
      username: 'jane.doe',
      password: 'secret',
      obscurePassword: true,
      hasSubmitted: false,
      loginStatus: AsyncData<void>(null),
    );

    test('are optional', () {
      expect(state.customHeaders, isEmpty);
      expect(state.isValid, isTrue);
      expect(state.parsedCustomHeaders, isEmpty);
    });

    test('make the form invalid when a line is not a header', () {
      final invalid = state.copyWith(customHeaders: 'broken');

      expect(invalid.isValid, isFalse);
      expect(invalid.customHeadersError('invalid', 'https'), isNull);
      expect(
        invalid
            .copyWith(hasSubmitted: true)
            .customHeadersError('invalid', 'https'),
        'invalid',
      );
    });

    test('are only accepted together with an HTTPS server URL', () {
      final headers = formatCustomHeaders(serviceTokenHeaders);
      final plainHttp = state.copyWith(
        serverUrl: 'http://example.com',
        customHeaders: headers,
        hasSubmitted: true,
      );

      expect(plainHttp.customHeadersNeedHttps, isTrue);
      expect(plainHttp.isValid, isFalse);
      expect(plainHttp.customHeadersError('invalid', 'https'), 'https');

      final withoutHeaders = plainHttp.copyWith(customHeaders: '');
      expect(withoutHeaders.isValid, isTrue);
      expect(withoutHeaders.customHeadersError('invalid', 'https'), isNull);

      final secure = plainHttp.copyWith(serverUrl: 'HTTPS://example.com');
      expect(secure.isValid, isTrue);
      expect(secure.customHeadersError('invalid', 'https'), isNull);
    });

    test('are restored by name only, without their values', () {
      final restored = LoginFormState.fromSession(
        const PaperlessAuthSession(
          serverUrl: 'https://example.com/',
          username: 'jane.doe',
          password: 'secret',
        ),
        customHeaders: serviceTokenHeaders,
      );

      expect(restored.customHeaders, isEmpty);
      expect(restored.savedCustomHeaderNames, <String>[
        'CF-Access-Client-Id',
        'CF-Access-Client-Secret',
      ]);
      expect(restored.isValid, isTrue);

      // Saved headers need HTTPS just like typed ones.
      final plainHttp = restored.copyWith(
        serverUrl: 'http://example.com',
        hasSubmitted: true,
      );
      expect(plainHttp.isValid, isFalse);
      expect(plainHttp.customHeadersError('invalid', 'https'), 'https');
    });
  });
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  RequestOptions? lastRequestOptions;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions requestOptions,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = requestOptions;

    return ResponseBody.fromBytes(
      utf8.encode('{}'),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }
}
