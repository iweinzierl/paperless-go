import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:paperless_ngx_app/src/core/network/dio_provider.dart';
import 'package:paperless_ngx_app/src/core/providers/shared_preferences_provider.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/auth_token_storage.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/connection_secrets_storage.dart';
import 'package:paperless_ngx_app/src/features/auth/data/repositories/auth_repository.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_method.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/login_controller.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/providers/custom_headers_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_certificates.dart';

/// Runs the real login and document requests over HTTPS against a local server
/// that, like an authenticating reverse proxy, only lets requests with the
/// right service token headers through to a small fake paperless-ngx API.
void main() {
  const customHeadersText =
      'CF-Access-Client-Id: client-id.access\n'
      'CF-Access-Client-Secret: client-secret';

  TestCertificates? certificates;
  HttpServer? server;
  late String serverUrl;
  late List<String> proxyLog;

  Future<ProviderContainer> createContainer() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final tokenStorage = await AuthTokenStorage.load(
      const FlutterSecureStorage(),
      sharedPreferences,
    );
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        authTokenStorageProvider.overrideWithValue(tokenStorage),
        connectionSecretsStorageProvider.overrideWithValue(
          await ConnectionSecretsStorage.load(
            const FlutterSecureStorage(),
            sharedPreferences,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> signIn(
    ProviderContainer container, {
    required String customHeaders,
    String? url,
  }) async {
    final controller = container.read(loginControllerProvider.notifier);
    controller.updateServerUrl(url ?? serverUrl);
    controller.updateUsername('jane.doe');
    controller.updatePassword('secret');
    controller.updateCustomHeaders(customHeaders);
    await controller.submit();
  }

  setUpAll(() async {
    certificates = await TestCertificates.generate();
  });

  setUp(() async {
    final generated = certificates;
    if (generated == null) {
      return;
    }

    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    SharedPreferences.setMockInitialValues(<String, Object>{});

    proxyLog = <String>[];
    final httpsServer = await HttpServer.bindSecure(
      InternetAddress.loopbackIPv4,
      0,
      SecurityContext()
        ..useCertificateChainBytes(generated.serverCertificatePem)
        ..usePrivateKeyBytes(generated.serverKeyPem),
    );
    server = httpsServer;
    serverUrl = 'https://127.0.0.1:${httpsServer.port}';
    httpsServer.listen((request) => _handle(request, proxyLog));
    HttpOverrides.global = TrustLocalTestServer(httpsServer.port);
  });

  tearDown(() async {
    await server?.close(force: true);
    server = null;
    HttpOverrides.global = null;
  });

  testWithCertificates(
    'signs in and loads data through the proxy with the headers',
    () => certificates,
    () async {
      final container = await createContainer();

      await signIn(container, customHeaders: customHeadersText);

      final loginState = container.read(loginControllerProvider);
      expect(loginState.loginStatus.hasError, isFalse);
      expect(loginState.connectedDisplayName, 'Jane Doe');
      expect(container.read(authSessionProvider).isAuthenticated, isTrue);

      final repository = container.read(documentsRepositoryProvider);
      expect(await repository.fetchSavedViews(), isEmpty);

      // Thumbnails and PDF previews are not loaded through Dio; they get their
      // headers from the repository.
      final client = HttpClient();
      addTearDown(client.close);
      final thumbnailRequest = await client.getUrl(
        repository.buildDocumentThumbnailUri(7),
      );
      repository.buildAuthenticatedHeaders().forEach(
        thumbnailRequest.headers.set,
      );
      final thumbnailResponse = await thumbnailRequest.close();
      await thumbnailResponse.drain<void>();
      expect(thumbnailResponse.statusCode, HttpStatus.ok);

      expect(proxyLog, <String>[
        'allowed POST /api/token/',
        'allowed GET /api/profile/',
        'allowed GET /api/saved_views/',
        'allowed GET /api/documents/7/thumb/',
      ]);
    },
  );

  testWithCertificates(
    'signs in with an API token through the proxy',
    () => certificates,
    () async {
      final container = await createContainer();
      final controller = container.read(loginControllerProvider.notifier);
      controller.updateServerUrl(serverUrl);
      controller.updateMethod(PaperlessAuthMethod.token);
      controller.updateToken('token-123');
      controller.updateCustomHeaders(customHeadersText);
      await controller.submit();

      expect(
        container.read(loginControllerProvider).loginStatus.hasError,
        isFalse,
      );
      expect(container.read(authSessionProvider).isAuthenticated, isTrue);
      expect(proxyLog, <String>['allowed GET /api/profile/']);
    },
  );

  testWithCertificates(
    'is turned away by the proxy without the headers',
    () => certificates,
    () async {
      final container = await createContainer();

      await signIn(container, customHeaders: '');

      final loginState = container.read(loginControllerProvider);
      expect(
        loginState.loginStatus.error,
        isA<AuthFailure>().having(
          (failure) => failure.code,
          'code',
          AuthFailureCode.serverRejectedLogin,
        ),
      );
      expect(container.read(authSessionProvider).isAuthenticated, isFalse);
      expect(proxyLog, <String>['blocked POST /api/token/']);
    },
  );

  testWithCertificates(
    'does not save the headers when the login fails',
    () => certificates,
    () async {
      final container = await createContainer();

      await signIn(
        container,
        customHeaders: 'CF-Access-Client-Id: client-id.access',
      );

      expect(
        container.read(loginControllerProvider).loginStatus.hasError,
        isTrue,
      );
      expect(
        await const FlutterSecureStorage().read(key: 'auth.custom_headers'),
        isNull,
      );
    },
  );

  testWithCertificates(
    'still sends the saved headers after an app restart',
    () => certificates,
    () async {
      await signIn(await createContainer(), customHeaders: customHeadersText);
      proxyLog.clear();

      // A new container reads everything from storage again, like a new start.
      final restarted = await createContainer();

      expect(restarted.read(authSessionProvider).isAuthenticated, isTrue);
      final restartedForm = restarted.read(loginControllerProvider);
      expect(restartedForm.customHeaders, isEmpty);
      expect(restartedForm.savedCustomHeaderNames, <String>[
        'CF-Access-Client-Id',
        'CF-Access-Client-Secret',
      ]);
      await restarted.read(documentsRepositoryProvider).fetchSavedViews();
      expect(proxyLog, <String>['allowed GET /api/saved_views/']);
    },
  );

  testWithCertificates(
    'signs in again with the saved headers without typing them again',
    () => certificates,
    () async {
      final container = await createContainer();
      await signIn(container, customHeaders: customHeadersText);
      await container.read(authSessionProvider.notifier).signOut();
      proxyLog.clear();

      // The form no longer has the values, only the names.
      expect(container.read(loginControllerProvider).customHeaders, isEmpty);
      await signIn(container, customHeaders: '');

      expect(container.read(authSessionProvider).isAuthenticated, isTrue);
      expect(proxyLog, <String>[
        'allowed POST /api/token/',
        'allowed GET /api/profile/',
      ]);
    },
  );

  testWithCertificates(
    'removes the saved headers at once',
    () => certificates,
    () async {
      final container = await createContainer();
      await signIn(container, customHeaders: customHeadersText);
      await container.read(authSessionProvider.notifier).signOut();
      proxyLog.clear();

      await container
          .read(loginControllerProvider.notifier)
          .removeSavedCustomHeaders();

      // Gone without another login.
      expect(
        await const FlutterSecureStorage().read(key: 'auth.custom_headers'),
        isNull,
      );
      expect(
        container.read(loginControllerProvider).savedCustomHeaderNames,
        isEmpty,
      );
      expect(container.read(customHeadersProvider), isEmpty);

      await signIn(container, customHeaders: '');
      expect(proxyLog, <String>['blocked POST /api/token/']);
    },
  );

  testWithCertificates(
    'does not follow a redirect that would carry the headers on',
    () => certificates,
    () async {
      final otherLog = <String>[];
      final otherServer = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      addTearDown(() => otherServer.close(force: true));
      otherServer.listen((request) => _handle(request, otherLog));
      final container = await createContainer();
      await signIn(container, customHeaders: customHeadersText);
      proxyLog.clear();

      await expectLater(
        container
            .read(dioProvider)
            .getUri(
              Uri.parse(
                '$serverUrl/redirect?to=http://127.0.0.1:${otherServer.port}/',
              ),
            ),
        throwsA(
          isA<DioException>().having(
            (error) => error.response?.statusCode,
            'status code',
            HttpStatus.found,
          ),
        ),
      );
      expect(proxyLog, <String>['allowed GET /redirect']);
      expect(otherLog, isEmpty);
    },
  );

  testWithCertificates(
    'never sends the headers over plain HTTP',
    () => certificates,
    () async {
      final plainServer = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      addTearDown(() => plainServer.close(force: true));
      plainServer.listen((request) => _handle(request, proxyLog));
      final plainUrl = 'http://127.0.0.1:${plainServer.port}';
      final container = await createContainer();

      // The login form refuses to sign in, so nothing is sent at all.
      await signIn(container, customHeaders: customHeadersText, url: plainUrl);

      final loginState = container.read(loginControllerProvider);
      expect(loginState.customHeadersNeedHttps, isTrue);
      expect(container.read(authSessionProvider).isAuthenticated, isFalse);
      expect(proxyLog, isEmpty);

      // Even a request that is made anyway goes out without the headers.
      container.read(customHeadersProvider.notifier).state = <String, String>{
        'CF-Access-Client-Id': 'client-id.access',
        'CF-Access-Client-Secret': 'client-secret',
      };
      await expectLater(
        container.read(dioProvider).getUri(Uri.parse('$plainUrl/api/profile/')),
        throwsA(isA<DioException>()),
      );
      expect(proxyLog, <String>['blocked GET /api/profile/']);
    },
  );
}

Future<void> _handle(HttpRequest request, List<String> proxyLog) async {
  final path = request.uri.path;
  final passesProxy =
      request.headers.value('CF-Access-Client-Id') == 'client-id.access' &&
      request.headers.value('CF-Access-Client-Secret') == 'client-secret';
  proxyLog.add(
    '${passesProxy ? 'allowed' : 'blocked'} ${request.method} $path',
  );
  await request.drain<void>();

  final response = request.response;
  void sendJson(int statusCode, Object body) {
    response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
  }

  if (!passesProxy) {
    response
      ..statusCode = HttpStatus.forbidden
      ..headers.contentType = ContentType.html
      ..write('<html><body>Forbidden</body></html>');
  } else if (path == '/redirect') {
    response
      ..statusCode = HttpStatus.found
      ..headers.set(
        HttpHeaders.locationHeader,
        request.uri.queryParameters['to']!,
      );
  } else if (path == '/api/token/' && request.method == 'POST') {
    sendJson(HttpStatus.ok, <String, Object>{'token': 'token-123'});
  } else if (request.headers.value('Authorization') != 'Token token-123') {
    sendJson(HttpStatus.unauthorized, <String, Object>{
      'detail': 'Invalid token.',
    });
  } else if (path == '/api/profile/') {
    sendJson(HttpStatus.ok, <String, Object>{
      'username': 'jane.doe',
      'first_name': 'Jane',
      'last_name': 'Doe',
    });
  } else if (path == '/api/saved_views/') {
    sendJson(HttpStatus.ok, <String, Object>{
      'count': 0,
      'results': <Object>[],
    });
  } else if (path == '/api/documents/7/thumb/') {
    response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.binary
      ..add(<int>[1, 2, 3]);
  } else {
    response.statusCode = HttpStatus.notFound;
  }

  await response.close();
}
