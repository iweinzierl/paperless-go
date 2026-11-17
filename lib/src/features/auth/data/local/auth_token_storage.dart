import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authTokenStorageProvider = Provider<AuthTokenStorage>((ref) {
  throw UnimplementedError('AuthTokenStorage must be overridden at app start.');
});

/// Keeps the auth token and the account password in the platform secure
/// storage (Keychain on iOS, Keystore-backed storage on Android). Both are
/// loaded once at app start and cached, so the session can still be read
/// synchronously.
class AuthTokenStorage {
  AuthTokenStorage._(this._secureStorage, this._token, this._password);

  // Same names, different stores: secure storage and shared preferences.
  static const _tokenKey = 'auth.token';
  static const _legacyTokenKey = 'auth.token';
  static const _passwordKey = 'auth.password';
  static const _legacyPasswordKey = 'auth.password';
  static const _serverUrlKey = 'auth.server_url';

  final FlutterSecureStorage _secureStorage;
  String? _token;
  String? _password;

  String? get token => _token;

  String? get password => _password;

  /// Never throws: any storage error is logged and leaves the user signed out,
  /// so app start can't fail on it.
  static Future<AuthTokenStorage> load(
    FlutterSecureStorage secureStorage,
    SharedPreferences sharedPreferences,
  ) async {
    // An entry restored from a backup can't be decrypted on a new device.
    var token = await _guard(
      'read the stored token',
      () => secureStorage.read(key: _tokenKey),
    );

    // Earlier versions kept the token in plain shared preferences.
    final legacyToken = sharedPreferences.getString(_legacyTokenKey);
    if (legacyToken != null) {
      token = await _guard('move the token to secure storage', () async {
        await secureStorage.write(key: _tokenKey, value: legacyToken);
        return legacyToken;
      });
      // Drop the plain copy even when the move failed, so it can't overwrite
      // a newer token on a later start.
      await _guard(
        'remove the plain token',
        () => sharedPreferences.remove(_legacyTokenKey),
      );
    }

    var password = await _guard(
      'read the stored password',
      () => secureStorage.read(key: _passwordKey),
    );

    // Earlier versions kept the password in plain shared preferences too.
    final legacyPassword = sharedPreferences.getString(_legacyPasswordKey);
    if (legacyPassword != null) {
      if (legacyPassword.isNotEmpty) {
        password = await _guard(
          'move the password to secure storage',
          () async {
            await secureStorage.write(key: _passwordKey, value: legacyPassword);
            return legacyPassword;
          },
        );
      }
      // Drop the plain copy even when the move failed: the user can type the
      // password again, but it must not stay readable.
      await _guard(
        'remove the plain password',
        () => sharedPreferences.remove(_legacyPasswordKey),
      );
    }

    // Keychain entries survive a reinstall on iOS, shared preferences don't.
    if (sharedPreferences.getString(_serverUrlKey) == null) {
      if (token != null) {
        await _guard(
          'delete an orphaned token',
          () => secureStorage.delete(key: _tokenKey),
        );
        token = null;
      }

      if (password != null) {
        await _guard(
          'delete an orphaned password',
          () => secureStorage.delete(key: _passwordKey),
        );
        password = null;
      }
    }

    return AuthTokenStorage._(secureStorage, token, password);
  }

  static Future<T?> _guard<T>(
    String action,
    Future<T?> Function() operation,
  ) async {
    try {
      return await operation();
    } on Exception catch (error) {
      log('AuthTokenStorage: could not $action: $error');
      return null;
    }
  }

  Future<void> write(String? token) async {
    if (token == null || token.isEmpty) {
      await delete();
      return;
    }

    await _secureStorage.write(key: _tokenKey, value: token);
    _token = token;
  }

  Future<void> delete() async {
    await _secureStorage.delete(key: _tokenKey);
    _token = null;
  }

  Future<void> writePassword(String? password) async {
    if (password == null || password.isEmpty) {
      await _secureStorage.delete(key: _passwordKey);
      _password = null;
      return;
    }

    await _secureStorage.write(key: _passwordKey, value: password);
    _password = password;
  }
}
