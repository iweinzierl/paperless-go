import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/connection_secrets_storage.dart';

/// The custom HTTP headers sent with every request to the paperless-ngx
/// server. Starts with the saved headers; the login form replaces them before
/// it signs in, so the sign-in requests already carry them.
final customHeadersProvider = StateProvider<Map<String, String>>((ref) {
  return ref.watch(connectionSecretsStorageProvider).customHeaders;
});
