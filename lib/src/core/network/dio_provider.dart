import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/custom_headers.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/providers/client_certificate_provider.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/providers/custom_headers_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  // Dio keeps its HTTP client, and a client keeps the certificate it was
  // created with, so a changed client certificate needs a new Dio.
  ref.watch(clientCertificateProvider);

  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    CustomHeadersInterceptor(() => ref.read(customHeadersProvider)),
  );

  return dio;
});

/// Adds the user's custom HTTP headers to every HTTPS request, so the app can
/// reach a server behind an authenticating reverse proxy. Requests over plain
/// HTTP go out without them.
class CustomHeadersInterceptor extends Interceptor {
  CustomHeadersInterceptor(this._readCustomHeaders);

  final Map<String, String> Function() _readCustomHeaders;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final customHeaders = _readCustomHeaders();
    if (customHeaders.isNotEmpty && allowsCustomHeaders(options.uri)) {
      options.headers = withCustomHeaders<dynamic>(
        options.headers,
        customHeaders,
      );
      // The HTTP client would send the headers along on a redirect, also to
      // another server or to plain HTTP. The paperless-ngx API has no
      // redirects that the app needs to follow.
      options.followRedirects = false;
    }

    handler.next(options);
  }
}
