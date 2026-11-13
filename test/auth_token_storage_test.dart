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
  });
}
