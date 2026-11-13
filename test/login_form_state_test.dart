import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/auth_preferences.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/auth_token_storage.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_method.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/login_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const tokenState = LoginFormState(
    serverUrl: 'https://example.com',
    username: '',
    password: '',
    obscurePassword: true,
    hasSubmitted: false,
    loginStatus: AsyncData<void>(null),
    method: PaperlessAuthMethod.token,
  );

  group('LoginFormState in token mode', () {
    test('is invalid with an empty token and shows the error after submit', () {
      final state = tokenState.copyWith(token: '   ');

      expect(state.isValid, isFalse);
      expect(state.tokenError('required'), isNull);

      final submitted = state.copyWith(hasSubmitted: true);

      expect(submitted.tokenError('required'), 'required');
      expect(submitted.usernameError('username'), isNull);
      expect(submitted.passwordError('password'), isNull);
    });

    test('is valid with a URL and a token but no username or password', () {
      final state = tokenState.copyWith(token: 'token-123');

      expect(state.isValid, isTrue);
      expect(state.copyWith(hasSubmitted: true).tokenError('required'), isNull);
    });

    test('is invalid with a bad server URL', () {
      final state = tokenState.copyWith(
        serverUrl: 'example.com',
        token: 'token-123',
      );

      expect(state.isValid, isFalse);
    });

    test('restores the method and token from a token session', () {
      final state = LoginFormState.fromSession(
        const PaperlessAuthSession(
          serverUrl: 'https://example.com/',
          username: 'jane.doe',
          password: '',
          authToken: 'token-123',
          method: PaperlessAuthMethod.token,
        ),
      );

      expect(state.method, PaperlessAuthMethod.token);
      expect(state.token, 'token-123');
      expect(state.obscureToken, isTrue);
    });
  });

  group('AuthPreferences', () {
    Future<AuthPreferences> createPreferences(
      SharedPreferences sharedPreferences,
    ) async {
      return AuthPreferences(
        sharedPreferences,
        await AuthTokenStorage.load(
          const FlutterSecureStorage(),
          sharedPreferences,
        ),
      );
    }

    setUp(() {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
    });

    test('round-trips the login method and keeps it on clear', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final sharedPreferences = await SharedPreferences.getInstance();
      final preferences = await createPreferences(sharedPreferences);

      await preferences.saveSession(
        const PaperlessAuthSession(
          serverUrl: 'https://example.com/',
          username: 'jane.doe',
          password: '',
          authToken: 'token-123',
          method: PaperlessAuthMethod.token,
        ),
      );

      expect(preferences.readSession().method, PaperlessAuthMethod.token);
      expect(preferences.readSession().authToken, 'token-123');
      expect(sharedPreferences.getString('auth.token'), isNull);
      expect(
        await const FlutterSecureStorage().read(key: 'auth.token'),
        'token-123',
      );

      await preferences.clearSession();

      final cleared = preferences.readSession();
      expect(sharedPreferences.getString('auth.method'), 'token');
      expect(cleared.method, PaperlessAuthMethod.token);
      expect(cleared.authToken, isNull);
      expect(
        await const FlutterSecureStorage().read(key: 'auth.token'),
        isNull,
      );
    });

    test('reads a missing method as password', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'auth.server_url': 'https://example.com/',
        'auth.username': 'jane.doe',
        'auth.password': 'secret',
        'auth.token': 'token-123',
      });
      final sharedPreferences = await SharedPreferences.getInstance();

      final preferences = await createPreferences(sharedPreferences);

      expect(preferences.readSession().method, PaperlessAuthMethod.password);
    });
  });
}
