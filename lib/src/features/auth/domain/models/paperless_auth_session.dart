import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_method.dart';

class PaperlessAuthSession {
  const PaperlessAuthSession({
    required this.serverUrl,
    required this.username,
    required this.password,
    this.authToken,
    this.displayName,
    this.method = PaperlessAuthMethod.password,
  });

  final String serverUrl;
  final String username;
  final String password;
  final String? authToken;
  final String? displayName;
  final PaperlessAuthMethod method;

  bool get isAuthenticated => authToken != null && authToken!.isNotEmpty;

  PaperlessAuthSession copyWith({
    String? serverUrl,
    String? username,
    String? password,
    String? authToken,
    String? displayName,
    PaperlessAuthMethod? method,
  }) {
    return PaperlessAuthSession(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      authToken: authToken ?? this.authToken,
      displayName: displayName ?? this.displayName,
      method: method ?? this.method,
    );
  }
}
