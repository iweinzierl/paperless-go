import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authTokenStorageProvider = Provider<AuthTokenStorage>((ref) {
  throw UnimplementedError('AuthTokenStorage must be overridden at app start.');
});

/// Keeps the auth token in the platform secure storage (Keychain on iOS,
/// Keystore-backed storage on Android). The token is loaded once at app start
/// and cached, so the session can still be read synchronously.
class AuthTokenStorage {
  AuthTokenStorage._(this._secureStorage, this._token);

  // Same name, different stores: secure storage and shared preferences.
  static const _tokenKey = 'auth.token';
  static const _legacyTokenKey = 'auth.token';
  static const _serverUrlKey = 'auth.server_url';

  final FlutterSecureStorage _secureStorage;
  String? _token;

  String? get token => _token;

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

    // Keychain entries survive a reinstall on iOS, shared preferences don't.
    if (token != null && sharedPreferences.getString(_serverUrlKey) == null) {
      await _guard(
        'delete an orphaned token',
        () => secureStorage.delete(key: _tokenKey),
      );
      token = null;
    }

    return AuthTokenStorage._(secureStorage, token);
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
}
