import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/auth_token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const secureStorage = FlutterSecureStorage();

  group('AuthTokenStorage', () {
    test('loads the token from secure storage', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'auth.token': 'token-123',
      });
      SharedPreferences.setMockInitialValues(<String, Object>{
        'auth.server_url': 'https://example.com/',
      });
      final sharedPreferences = await SharedPreferences.getInstance();

      final storage = await AuthTokenStorage.load(
        secureStorage,
        sharedPreferences,
      );

      expect(storage.token, 'token-123');
    });

    test('moves a token from shared preferences to secure storage', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      SharedPreferences.setMockInitialValues(<String, Object>{
        'auth.server_url': 'https://example.com/',
        'auth.token': 'legacy-token',
      });
      final sharedPreferences = await SharedPreferences.getInstance();

      final storage = await AuthTokenStorage.load(
        secureStorage,
        sharedPreferences,
      );

      expect(storage.token, 'legacy-token');
      expect(sharedPreferences.containsKey('auth.token'), isFalse);
      expect(await secureStorage.read(key: 'auth.token'), 'legacy-token');
    });

    test('drops a token left over without a saved server', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'auth.token': 'orphaned-token',
      });
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final sharedPreferences = await SharedPreferences.getInstance();

      final storage = await AuthTokenStorage.load(
        secureStorage,
        sharedPreferences,
      );

      expect(storage.token, isNull);
      expect(await secureStorage.read(key: 'auth.token'), isNull);
    });

    test('writes and deletes the token', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final sharedPreferences = await SharedPreferences.getInstance();
      final storage = await AuthTokenStorage.load(
        secureStorage,
        sharedPreferences,
      );

      await storage.write('token-123');

      expect(storage.token, 'token-123');
      expect(await secureStorage.read(key: 'auth.token'), 'token-123');

      await storage.write('');

      expect(storage.token, isNull);
      expect(await secureStorage.read(key: 'auth.token'), isNull);
    });

    test('loads signed out when reading secure storage fails', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'auth.server_url': 'https://example.com/',
      });
      final sharedPreferences = await SharedPreferences.getInstance();

      final storage = await AuthTokenStorage.load(
        const _FailingSecureStorage(failRead: true),
        sharedPreferences,
      );

      expect(storage.token, isNull);
    });

    test(
      'loads signed out and drops the plain token when migration fails',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'auth.server_url': 'https://example.com/',
          'auth.token': 'legacy-token',
        });
        final sharedPreferences = await SharedPreferences.getInstance();

        final storage = await AuthTokenStorage.load(
          const _FailingSecureStorage(failRead: true, failWrite: true),
          sharedPreferences,
        );

        expect(storage.token, isNull);
        expect(sharedPreferences.containsKey('auth.token'), isFalse);
      },
    );

    test('loads signed out when deleting an orphaned token fails', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final sharedPreferences = await SharedPreferences.getInstance();

      final storage = await AuthTokenStorage.load(
        const _FailingSecureStorage(
          storedToken: 'orphaned-token',
          failDelete: true,
        ),
        sharedPreferences,
      );

      expect(storage.token, isNull);
    });
  });
}

class _FailingSecureStorage extends FlutterSecureStorage {
  const _FailingSecureStorage({
    this.storedToken,
    this.failRead = false,
    this.failWrite = false,
    this.failDelete = false,
  });

  final String? storedToken;
  final bool failRead;
  final bool failWrite;
  final bool failDelete;

  static final _error = PlatformException(code: 'secure-storage-failure');

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failRead) {
      throw _error;
    }

    return storedToken;
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failWrite) {
      throw _error;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failDelete) {
      throw _error;
    }
  }
}
