import 'dart:convert';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/client_certificate.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden at app start with the loaded storage. Without that it starts
/// empty and still saves, which is all that tests need.
final connectionSecretsStorageProvider = Provider<ConnectionSecretsStorage>((
  ref,
) {
  return ConnectionSecretsStorage.empty(const FlutterSecureStorage());
});

/// Keeps what the app needs to get through to a server behind an
/// authenticating reverse proxy: the custom HTTP headers and the TLS client
/// certificate. Both are secrets, so they live in the platform secure storage
/// (Keychain on iOS, Keystore-backed storage on Android). They are loaded once
/// at app start and cached, so they can be read synchronously.
class ConnectionSecretsStorage {
  ConnectionSecretsStorage._(
    this._secureStorage,
    this._customHeaders,
    this._clientCertificate,
  );

  ConnectionSecretsStorage.empty(FlutterSecureStorage secureStorage)
    : this._(secureStorage, const <String, String>{}, null);

  static const _customHeadersKey = 'auth.custom_headers';
  static const _clientCertificateKey = 'auth.client_certificate';
  static const _serverUrlKey = 'auth.server_url';

  final FlutterSecureStorage _secureStorage;
  Map<String, String> _customHeaders;
  ClientCertificate? _clientCertificate;

  Map<String, String> get customHeaders => _customHeaders;

  ClientCertificate? get clientCertificate => _clientCertificate;

  /// Never throws: any storage error is logged and leaves the storage empty,
  /// so app start can't fail on it.
  static Future<ConnectionSecretsStorage> load(
    FlutterSecureStorage secureStorage,
    SharedPreferences sharedPreferences,
  ) async {
    // An entry restored from a backup can't be decrypted on a new device.
    var customHeaders =
        await _guard(
          'read the custom headers',
          () async => _decodeCustomHeaders(
            await secureStorage.read(key: _customHeadersKey),
          ),
        ) ??
        const <String, String>{};
    var clientCertificate = await _guard(
      'read the client certificate',
      () async => _decodeClientCertificate(
        await secureStorage.read(key: _clientCertificateKey),
      ),
    );

    // Keychain entries survive a reinstall on iOS, shared preferences don't.
    if (sharedPreferences.getString(_serverUrlKey) == null) {
      if (customHeaders.isNotEmpty) {
        await _guard(
          'delete orphaned custom headers',
          () => secureStorage.delete(key: _customHeadersKey),
        );
        customHeaders = const <String, String>{};
      }

      if (clientCertificate != null) {
        await _guard(
          'delete an orphaned client certificate',
          () => secureStorage.delete(key: _clientCertificateKey),
        );
        clientCertificate = null;
      }
    }

    return ConnectionSecretsStorage._(
      secureStorage,
      customHeaders,
      clientCertificate,
    );
  }

  Future<void> writeCustomHeaders(Map<String, String> customHeaders) async {
    if (customHeaders.isEmpty) {
      await _secureStorage.delete(key: _customHeadersKey);
    } else {
      await _secureStorage.write(
        key: _customHeadersKey,
        value: jsonEncode(customHeaders),
      );
    }

    _customHeaders = Map<String, String>.unmodifiable(customHeaders);
  }

  Future<void> writeClientCertificate(ClientCertificate? certificate) async {
    if (certificate == null) {
      await _secureStorage.delete(key: _clientCertificateKey);
    } else {
      await _secureStorage.write(
        key: _clientCertificateKey,
        value: jsonEncode(certificate.toJson()),
      );
    }

    _clientCertificate = certificate;
  }

  static Map<String, String>? _decodeCustomHeaders(String? encoded) {
    final decoded = _decodeJsonMap(encoded);
    if (decoded == null) {
      return null;
    }

    return Map<String, String>.unmodifiable(<String, String>{
      for (final entry in decoded.entries) entry.key: entry.value.toString(),
    });
  }

  static ClientCertificate? _decodeClientCertificate(String? encoded) {
    final decoded = _decodeJsonMap(encoded);
    if (decoded == null) {
      return null;
    }

    try {
      return ClientCertificate.fromJson(decoded);
    } catch (_) {
      // Not logged, for the same reason as in [_decodeJsonMap].
      return null;
    }
  }

  static Map<String, dynamic>? _decodeJsonMap(String? encoded) {
    if (encoded == null || encoded.isEmpty) {
      return null;
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException {
      // Not passed on to be logged: the message quotes the stored secrets.
      return null;
    }

    return decoded is Map<String, dynamic> ? decoded : null;
  }

  static Future<T?> _guard<T>(
    String action,
    Future<T?> Function() operation,
  ) async {
    try {
      return await operation();
    } on Exception catch (error) {
      log('ConnectionSecretsStorage: could not $action: $error');
      return null;
    }
  }
}
