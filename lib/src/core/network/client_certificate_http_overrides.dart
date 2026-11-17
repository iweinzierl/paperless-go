import 'dart:developer';
import 'dart:io';

import 'package:paperless_ngx_app/src/features/auth/domain/models/client_certificate.dart';

/// Makes every HTTP client of the app present [certificate], or none when it
/// is null. Returns false, and changes nothing, when the certificate can't be
/// read, for example because its password is wrong.
bool applyClientCertificate(ClientCertificate? certificate) {
  final SecurityContext? context;
  try {
    context = certificate?.toSecurityContext();
  } on Exception catch (error) {
    // A TlsException has no certificate data or password in it.
    log('Could not read the client certificate: $error');
    return false;
  }

  ClientCertificateHttpOverrides.apply(context);
  return true;
}

/// Gives HTTP clients the security context with the client certificate.
///
/// This is global, because images and PDF previews are loaded by clients the
/// app doesn't create itself. Only HTTPS servers that ask for a client
/// certificate get to see it.
class ClientCertificateHttpOverrides extends HttpOverrides {
  ClientCertificateHttpOverrides._(this._previous);

  static ClientCertificateHttpOverrides? _installed;

  final HttpOverrides? _previous;
  SecurityContext? _context;

  static void apply(SecurityContext? context) {
    var overrides = _installed;
    if (overrides == null || HttpOverrides.current != overrides) {
      if (context == null) {
        // Not installed, so there is nothing to take back.
        return;
      }

      overrides = ClientCertificateHttpOverrides._(HttpOverrides.current);
      _installed = overrides;
      HttpOverrides.global = overrides;
    }

    overrides._context = context;
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final effectiveContext = context ?? _context;
    final previous = _previous;
    if (previous != null) {
      return previous.createHttpClient(effectiveContext);
    }

    return super.createHttpClient(effectiveContext);
  }

  @override
  String findProxyFromEnvironment(Uri url, Map<String, String>? environment) {
    final previous = _previous;
    if (previous != null) {
      return previous.findProxyFromEnvironment(url, environment);
    }

    return super.findProxyFromEnvironment(url, environment);
  }
}
