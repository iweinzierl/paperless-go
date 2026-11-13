import 'dart:developer';

import 'package:flutter/services.dart';
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

  static const _tokenKey = 'auth.token';
  static const _legacyTokenKey = 'auth.token';
  static const _serverUrlKey = 'auth.server_url';

  final FlutterSecureStorage _secureStorage;
  String? _token;

  String? get token => _token;

  static Future<AuthTokenStorage> load(
    FlutterSecureStorage secureStorage,
    SharedPreferences sharedPreferences,
  ) async {
    String? token;
    try {
      token = await secureStorage.read(key: _tokenKey);
    } on PlatformException catch (error) {
      // An entry restored from a backup can't be decrypted on a new device.
      log('AuthTokenStorage: could not read the stored token: $error');
    }

    // Earlier versions kept the token in plain shared preferences.
    final legacyToken = sharedPreferences.getString(_legacyTokenKey);
    if (legacyToken != null) {
      await secureStorage.write(key: _tokenKey, value: legacyToken);
      await sharedPreferences.remove(_legacyTokenKey);
      token = legacyToken;
    }

    // Keychain entries survive a reinstall on iOS, shared preferences don't.
    if (token != null && sharedPreferences.getString(_serverUrlKey) == null) {
      await secureStorage.delete(key: _tokenKey);
      token = null;
    }

    return AuthTokenStorage._(secureStorage, token);
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
