import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/network/dio_provider.dart';
import 'package:paperless_ngx_app/src/features/auth/data/remote/models/paperless_auth_token_request.dart';
import 'package:paperless_ngx_app/src/features/auth/data/remote/models/paperless_auth_token_response.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  Future<PaperlessAuthSession> signIn({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final normalizedServerUrl = normalizePaperlessBaseUrl(serverUrl);
    final apiBaseUri = buildPaperlessApiBaseUri(normalizedServerUrl);

    try {
      final tokenResponse = await _createToken(
        apiBaseUri,
        PaperlessAuthTokenRequest(username: username, password: password),
      );
      final profile = await _getProfile(apiBaseUri, tokenResponse.token);

      return PaperlessAuthSession(
        serverUrl: normalizedServerUrl,
        username: username,
        password: password,
        authToken: tokenResponse.token,
        displayName: profile.displayName,
      );
    } on DioException catch (error) {
      throw AuthFailure(_messageFromError(error));
    }
  }

  Future<PaperlessAuthTokenResponse> _createToken(
    Uri apiBaseUri,
    PaperlessAuthTokenRequest request,
  ) async {
    final response = await _dio.postUri(
      apiBaseUri.resolve('token/'),
      data: request.toJson(),
      options: Options(contentType: Headers.jsonContentType),
    );

    final payload = _asJsonMap(response.data);

    return PaperlessAuthTokenResponse.fromJson(payload);
  }

  Future<PaperlessUserProfile> _getProfile(Uri apiBaseUri, String token) async {
    final response = await _dio.getUri(
      apiBaseUri.resolve('profile/'),
      options: Options(
        headers: <String, Object>{'Authorization': 'Token $token'},
      ),
    );

    final payload = _asJsonMap(response.data);

    return PaperlessUserProfile.fromJson(payload);
  }

  Map<String, dynamic> _asJsonMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }

    throw const AuthFailure('The server returned an unexpected response.');
  }

  String _messageFromError(DioException error) {
    final responseData = error.response?.data;

    if (responseData is Map<String, dynamic>) {
      final nonFieldErrors = responseData['non_field_errors'];
      if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
        return nonFieldErrors.first.toString();
      }

      final details = responseData['detail'];
      if (details is String && details.isNotEmpty) {
        return details;
      }
    }

    if (responseData is String && responseData.contains('CSRF')) {
      return 'The request reached the wrong paperless page instead of the API. Check the base URL, especially if the server is hosted below a subpath.';
    }

    if (error.response?.statusCode == 400 ||
        error.response?.statusCode == 401) {
      return 'Authentication failed. Check your URL, username, and password.';
    }

    if (error.response?.statusCode == 403) {
      return 'The server rejected the login request. Check the base URL, especially if paperless-ngx is hosted below a subpath.';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Unable to reach the paperless-ngx server.';
    }

    return 'Login failed. Please try again.';
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

String normalizePaperlessBaseUrl(String serverUrl) {
  final trimmed = serverUrl.trim();
  final uri = Uri.tryParse(trimmed);

  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    throw const AuthFailure(
      'Enter a valid server URL including http:// or https://.',
    );
  }

  var normalizedPath = uri.path.replaceFirst(RegExp(r'/+$'), '');
  if (normalizedPath.endsWith('/api')) {
    normalizedPath = normalizedPath.substring(
      0,
      normalizedPath.length - '/api'.length,
    );
  }

  if (normalizedPath.isEmpty) {
    normalizedPath = '/';
  } else {
    normalizedPath = '$normalizedPath/';
  }

  return uri
      .replace(path: normalizedPath, query: null, fragment: null)
      .toString();
}

Uri buildPaperlessApiBaseUri(String normalizedServerUrl) {
  return Uri.parse(normalizedServerUrl).resolve('api/');
}
