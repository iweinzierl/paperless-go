import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_ngx_app/src/core/providers/shared_preferences_provider.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/auth_token_storage.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/connection_secrets_storage.dart';
import 'package:paperless_ngx_app/src/features/auth/data/repositories/auth_repository.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/client_certificate.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/login_controller.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/providers/client_certificate_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_certificates.dart';

void main() {
  const password = TestCertificates.clientP12Password;

  // Enough for everything that only stores or passes the file on.
  final placeholderBytes = Uint8List.fromList(<int>[1, 2, 3]);

  TestCertificates? certificates;

  setUpAll(() async {
    certificates = await TestCertificates.generate();
  });

  ClientCertificate certificate({Uint8List? bytes, String? withPassword}) {
    return ClientCertificate(
      fileName: 'client.p12',
      bytes: bytes ?? placeholderBytes,
      password: withPassword ?? password,
    );
  }

  group('ClientCertificate', () {
    testWithCertificates(
      'reads a PKCS #12 file with the right password',
      () => certificates,
      () async {
        expect(
          certificate(bytes: certificates!.clientP12).toSecurityContext(),
          isA<SecurityContext>(),
        );
      },
    );

    testWithCertificates(
      'cannot be read with a wrong password',
      () => certificates,
      () async {
        expect(
          () => certificate(
            bytes: certificates!.clientP12,
            withPassword: 'wrong',
          ).toSecurityContext(),
          throwsA(isA<TlsException>()),
        );
      },
    );

    test('cannot be read from a file that is not a certificate', () {
      expect(
        () => ClientCertificate(
          fileName: 'notes.txt',
          bytes: Uint8List.fromList(utf8.encode('not a certificate')),
          password: password,
        ).toSecurityContext(),
        throwsA(isA<TlsException>()),
      );
    });

    test('round-trips through JSON', () {
      final restored = ClientCertificate.fromJson(
        jsonDecode(jsonEncode(certificate().toJson())) as Map<String, dynamic>,
      );

      expect(restored.fileName, 'client.p12');
      expect(restored.bytes, placeholderBytes);
      expect(restored.password, password);
    });
  });

  group('ConnectionSecretsStorage client certificate', () {
    const secureStorage = FlutterSecureStorage();

    test('writes, reloads and deletes the client certificate', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      SharedPreferences.setMockInitialValues(<String, Object>{
        'auth.server_url': 'https://example.com/',
      });
      final sharedPreferences = await SharedPreferences.getInstance();
      final storage = await ConnectionSecretsStorage.load(
        secureStorage,
        sharedPreferences,
      );

      expect(storage.clientCertificate, isNull);

      await storage.writeClientCertificate(certificate());

      // Only in the secure storage, never in the plain preferences.
      expect(sharedPreferences.getKeys(), <String>{'auth.server_url'});

      final reloaded = await ConnectionSecretsStorage.load(
        secureStorage,
        sharedPreferences,
      );

      expect(reloaded.clientCertificate?.fileName, 'client.p12');
      expect(reloaded.clientCertificate?.bytes, placeholderBytes);
      expect(reloaded.clientCertificate?.password, password);

      await reloaded.writeClientCertificate(null);

      expect(reloaded.clientCertificate, isNull);
      expect(await secureStorage.read(key: 'auth.client_certificate'), isNull);
    });

    test('drops a certificate left over without a saved server', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'auth.client_certificate': jsonEncode(certificate().toJson()),
      });
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final sharedPreferences = await SharedPreferences.getInstance();

      final storage = await ConnectionSecretsStorage.load(
        secureStorage,
        sharedPreferences,
      );

      expect(storage.clientCertificate, isNull);
      expect(await secureStorage.read(key: 'auth.client_certificate'), isNull);
    });

    test('ignores a stored certificate that cannot be decoded', () async {
      for (final stored in <String>['not json', '{"file_name": 1}', '[]']) {
        FlutterSecureStorage.setMockInitialValues(<String, String>{
          'auth.client_certificate': stored,
        });
        SharedPreferences.setMockInitialValues(<String, Object>{
          'auth.server_url': 'https://example.com/',
        });
        final sharedPreferences = await SharedPreferences.getInstance();

        final storage = await ConnectionSecretsStorage.load(
          secureStorage,
          sharedPreferences,
        );

        expect(storage.clientCertificate, isNull);
      }
    });
  });

  group('LoginFormState client certificate', () {
    const state = LoginFormState(
      serverUrl: 'https://example.com',
      username: 'jane.doe',
      password: 'secret',
      obscurePassword: true,
      hasSubmitted: true,
      loginStatus: AsyncData<void>(null),
    );

    test('is optional', () {
      expect(state.clientCertificate, isNull);
      expect(state.isValid, isTrue);
      expect(state.clientCertificateError('unreadable', 'https'), isNull);
    });

    test('is only accepted together with an HTTPS server URL', () {
      final plainHttp = state.copyWith(
        serverUrl: 'http://example.com',
        clientCertificateFileName: 'client.p12',
        clientCertificateBytes: placeholderBytes,
      );

      expect(plainHttp.isValid, isFalse);
      expect(plainHttp.clientCertificateError('unreadable', 'https'), 'https');
      expect(plainHttp.copyWith(removeClientCertificate: true).isValid, isTrue);
    });

    test('is restored next to a session and can be removed', () {
      final restored = LoginFormState.fromSession(
        const PaperlessAuthSession(
          serverUrl: 'https://example.com/',
          username: 'jane.doe',
          password: 'secret',
        ),
        clientCertificate: certificate(),
      );

      expect(restored.clientCertificateFileName, 'client.p12');
      expect(restored.clientCertificate?.password, password);

      final removed = restored.copyWith(removeClientCertificate: true);

      expect(removed.clientCertificate, isNull);
      expect(removed.clientCertificateFileName, isNull);
      expect(removed.clientCertificatePassword, isEmpty);
    });
  });

  test('shows an error when the picked file cannot be a certificate', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final sharedPreferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        authTokenStorageProvider.overrideWithValue(
          await AuthTokenStorage.load(
            const FlutterSecureStorage(),
            sharedPreferences,
          ),
        ),
        clientCertificatePickerProvider.overrideWithValue(
          const _RejectingClientCertificatePicker(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(loginControllerProvider.notifier)
        .pickClientCertificate();

    final loginState = container.read(loginControllerProvider);
    expect(loginState.clientCertificate, isNull);
    expect(
      loginState.clientCertificateError('unreadable', 'https'),
      'unreadable',
    );
  });

  // Runs the real login and document requests against a local HTTPS server  // that asks for a client certificate and, like a proxy enforcing mTLS, only
  // lets requests through that present the right one.
  group('against a server that requires mTLS', () {
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
          clientCertificatePickerProvider.overrideWithValue(
            _FakeClientCertificatePicker(() => certificates!.clientP12),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    Future<void> signIn(
      ProviderContainer container, {
      String? certificatePassword,
    }) async {
      final controller = container.read(loginControllerProvider.notifier);
      controller.updateServerUrl(serverUrl);
      controller.updateUsername('jane.doe');
      controller.updatePassword('secret');
      if (certificatePassword != null) {
        await controller.pickClientCertificate();
        controller.updateClientCertificatePassword(certificatePassword);
      }
      await controller.submit();
    }

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
          ..usePrivateKeyBytes(generated.serverKeyPem)
          ..setTrustedCertificatesBytes(generated.clientCertificatePem)
          ..setClientAuthoritiesBytes(generated.clientCertificatePem),
        requestClientCertificate: true,
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
      'signs in and loads data with the certificate',
      () => certificates,
      () async {
        final container = await createContainer();

        await signIn(container, certificatePassword: password);

        final loginState = container.read(loginControllerProvider);
        expect(loginState.loginStatus.hasError, isFalse);
        expect(loginState.connectedDisplayName, 'Jane Doe');
        expect(container.read(authSessionProvider).isAuthenticated, isTrue);

        final repository = container.read(documentsRepositoryProvider);
        expect(await repository.fetchSavedViews(), isEmpty);

        // Thumbnails and PDF previews are loaded by HTTP clients the app
        // doesn't create itself; they have to present the certificate too.
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
      'sends custom headers together with the certificate',
      () => certificates,
      () async {
        final container = await createContainer();
        container
            .read(loginControllerProvider.notifier)
            .updateCustomHeaders('X-Proxy-Token: proxy-token');

        await signIn(container, certificatePassword: password);

        expect(container.read(authSessionProvider).isAuthenticated, isTrue);
        expect(proxyLog, <String>[
          'allowed POST /api/token/ with X-Proxy-Token',
          'allowed GET /api/profile/ with X-Proxy-Token',
        ]);
      },
    );

    testWithCertificates(
      'is turned away without a certificate',
      () => certificates,
      () async {
        final container = await createContainer();

        await signIn(container);

        expect(
          container.read(loginControllerProvider).loginStatus.error,
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
      'does not sign in with a wrong certificate password',
      () => certificates,
      () async {
        final container = await createContainer();

        await signIn(container, certificatePassword: 'wrong');

        final loginState = container.read(loginControllerProvider);
        expect(loginState.clientCertificateUnreadable, isTrue);
        expect(
          loginState.clientCertificateError('unreadable', 'https'),
          'unreadable',
        );
        expect(loginState.isSubmitting, isFalse);
        expect(proxyLog, isEmpty);
        expect(
          await const FlutterSecureStorage().read(
            key: 'auth.client_certificate',
          ),
          isNull,
        );
      },
    );

    testWithCertificates(
      'still presents the saved certificate after a restart',
      () => certificates,
      () async {
        await signIn(await createContainer(), certificatePassword: password);
        proxyLog.clear();

        // A new container reads everything from storage again, like a new
        // start of the app.
        final restarted = await createContainer();

        expect(restarted.read(authSessionProvider).isAuthenticated, isTrue);
        expect(
          restarted.read(loginControllerProvider).clientCertificateFileName,
          'client.p12',
        );
        await restarted.read(documentsRepositoryProvider).fetchSavedViews();
        expect(proxyLog, <String>['allowed GET /api/saved_views/']);
      },
    );

    testWithCertificates(
      'stops presenting the certificate once it is removed',
      () => certificates,
      () async {
        final container = await createContainer();
        await signIn(container, certificatePassword: password);
        proxyLog.clear();

        await container
            .read(loginControllerProvider.notifier)
            .removeClientCertificate();

        // Gone at once, without another login.
        expect(
          await const FlutterSecureStorage().read(
            key: 'auth.client_certificate',
          ),
          isNull,
        );
        await container.read(loginControllerProvider.notifier).submit();

        expect(proxyLog, <String>['blocked POST /api/token/']);
      },
    );
  });
}

class _RejectingClientCertificatePicker implements ClientCertificatePicker {
  const _RejectingClientCertificatePicker();

  @override
  Future<PickedClientCertificateFile?> pick() async {
    throw const ClientCertificateFileException();
  }
}

class _FakeClientCertificatePicker implements ClientCertificatePicker {
  const _FakeClientCertificatePicker(this._readBytes);

  final Uint8List Function() _readBytes;

  @override
  Future<PickedClientCertificateFile?> pick() async {
    return (fileName: 'client.p12', bytes: _readBytes());
  }
}

Future<void> _handle(HttpRequest request, List<String> proxyLog) async {
  final path = request.uri.path;
  final passesProxy = request.certificate != null;
  final proxyToken = request.headers.value('X-Proxy-Token') == null
      ? ''
      : ' with X-Proxy-Token';
  proxyLog.add(
    '${passesProxy ? 'allowed' : 'blocked'} ${request.method} $path$proxyToken',
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
