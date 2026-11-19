import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/network/client_certificate_http_overrides.dart';
import 'package:paperless_ngx_app/src/core/providers/shared_preferences_provider.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/auth_preferences.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/auth_token_storage.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/connection_secrets_storage.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/client_certificate.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/custom_headers.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_method.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/providers/client_certificate_provider.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/providers/custom_headers_provider.dart';
import 'package:paperless_ngx_app/src/features/auth/data/repositories/auth_repository.dart';

final authPreferencesProvider = Provider<AuthPreferences>((ref) {
  return AuthPreferences(
    ref.watch(sharedPreferencesProvider),
    ref.watch(authTokenStorageProvider),
  );
});

final loginControllerProvider =
    NotifierProvider<LoginController, LoginFormState>(LoginController.new);

class LoginController extends Notifier<LoginFormState> {
  AuthPreferences get _authPreferences => ref.read(authPreferencesProvider);
  AuthRepository get _authRepository => ref.read(authRepositoryProvider);
  ConnectionSecretsStorage get _connectionSecrets =>
      ref.read(connectionSecretsStorageProvider);
  AuthSessionController get _authSessionController =>
      ref.read(authSessionProvider.notifier);

  @override
  LoginFormState build() {
    final savedSession = _authPreferences.readSession();

    return LoginFormState.fromSession(
      savedSession,
      customHeaders: _connectionSecrets.customHeaders,
      clientCertificate: _connectionSecrets.clientCertificate,
    );
  }

  void updateServerUrl(String value) {
    state = state.copyWith(serverUrl: value);
  }

  void updateUsername(String value) {
    state = state.copyWith(username: value);
  }

  void updatePassword(String value) {
    state = state.copyWith(password: value);
  }

  void updateMfaCode(String value) {
    state = state.copyWith(mfaCode: value);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void updateMethod(PaperlessAuthMethod value) {
    state = state.copyWith(method: value);
  }

  void updateToken(String value) {
    state = state.copyWith(token: value);
  }

  void toggleTokenVisibility() {
    state = state.copyWith(obscureToken: !state.obscureToken);
  }

  void updateCustomHeaders(String value) {
    state = state.copyWith(customHeaders: value);
  }

  Future<void> pickClientCertificate() async {
    try {
      final picked = await ref.read(clientCertificatePickerProvider).pick();
      if (picked == null) {
        return;
      }

      state = state.copyWith(
        clientCertificateFileName: picked.fileName,
        clientCertificateBytes: picked.bytes,
        clientCertificateUnreadable: false,
      );
    } on Exception catch (error) {
      log('Could not pick a client certificate: $error');
      state = state.copyWith(clientCertificateUnreadable: true);
    }
  }

  /// Takes effect at once, not only with the next login: the certificate is
  /// removed from the form, from the running app and from the storage.
  Future<void> removeClientCertificate() async {
    state = state.copyWith(removeClientCertificate: true);
    applyClientCertificate(null);
    ref.read(clientCertificateProvider.notifier).state = null;
    await _connectionSecrets.writeClientCertificate(null);
  }

  /// Takes effect at once, like [removeClientCertificate].
  Future<void> removeSavedCustomHeaders() async {
    state = state.copyWith(savedCustomHeaderNames: const <String>[]);
    ref.read(customHeadersProvider.notifier).state = const <String, String>{};
    await _connectionSecrets.writeCustomHeaders(const <String, String>{});
  }

  void updateClientCertificatePassword(String value) {
    state = state.copyWith(
      clientCertificatePassword: value,
      clientCertificateUnreadable: false,
    );
  }

  Future<void> submit() async {
    final nextState = state.copyWith(
      hasSubmitted: true,
      loginStatus: const AsyncLoading<void>(),
    );

    if (!nextState.isValid) {
      state = nextState.copyWith(loginStatus: const AsyncData<void>(null));
      return;
    }

    // Checked here and not on every rebuild: it parses the whole file.
    final clientCertificate = nextState.clientCertificate;
    if (!applyClientCertificate(clientCertificate)) {
      state = nextState.copyWith(
        clientCertificateUnreadable: true,
        loginStatus: const AsyncData<void>(null),
      );
      return;
    }

    state = nextState;

    // Set before signing in, so the sign-in requests already use them.
    ref.read(clientCertificateProvider.notifier).state = clientCertificate;
    // Typed headers replace the saved ones. The form never shows the saved
    // values, so with nothing typed the saved ones stay in use.
    final typedHeaders = state.parsedCustomHeaders ?? const <String, String>{};
    final customHeaders = typedHeaders.isNotEmpty
        ? typedHeaders
        : _connectionSecrets.customHeaders;
    ref.read(customHeadersProvider.notifier).state = customHeaders;

    final result = await AsyncValue.guard<PaperlessAuthSession>(() async {
      final session = state.method == PaperlessAuthMethod.token
          ? await _authRepository.signInWithToken(
              serverUrl: state.serverUrl,
              token: state.token.trim(),
            )
          : await _authRepository.signIn(
              serverUrl: state.serverUrl,
              username: state.username,
              password: state.password,
              code: state.mfaCode,
            );
      await _authPreferences.saveSession(session);
      await _connectionSecrets.writeCustomHeaders(customHeaders);
      await _connectionSecrets.writeClientCertificate(clientCertificate);
      return session;
    });

    state = state.copyWith(mfaCode: '');

    result.when(
      data: (session) {
        _authSessionController.setSession(session);
        state = state.copyWith(
          loginStatus: const AsyncData<void>(null),
          connectedDisplayName: session.displayName,
          // Saved now, so the values are no longer shown.
          customHeaders: '',
          savedCustomHeaderNames: customHeaders.keys.toList(growable: false),
        );
      },
      error: (error, stackTrace) {
        state = state.copyWith(
          loginStatus: AsyncError<void>(error, stackTrace),
        );
      },
      loading: () {},
    );
  }
}

class LoginFormState {
  const LoginFormState({
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.obscurePassword,
    required this.hasSubmitted,
    required this.loginStatus,
    this.method = PaperlessAuthMethod.password,
    this.token = '',
    this.obscureToken = true,
    this.mfaCode = '',
    this.customHeaders = '',
    this.savedCustomHeaderNames = const <String>[],
    this.clientCertificateFileName,
    this.clientCertificateBytes,
    this.clientCertificatePassword = '',
    this.clientCertificateUnreadable = false,
    this.connectedDisplayName,
  });

  factory LoginFormState.fromSession(
    PaperlessAuthSession session, {
    Map<String, String> customHeaders = const <String, String>{},
    ClientCertificate? clientCertificate,
  }) {
    return LoginFormState(
      serverUrl: session.serverUrl,
      username: session.username,
      password: session.password,
      obscurePassword: true,
      hasSubmitted: false,
      loginStatus: const AsyncData<void>(null),
      method: session.method,
      token: session.method == PaperlessAuthMethod.token
          ? session.authToken ?? ''
          : '',
      savedCustomHeaderNames: customHeaders.keys.toList(growable: false),
      clientCertificateFileName: clientCertificate?.fileName,
      clientCertificateBytes: clientCertificate?.bytes,
      clientCertificatePassword: clientCertificate?.password ?? '',
      connectedDisplayName: session.displayName,
    );
  }

  final String serverUrl;
  final String username;
  final String password;
  final bool obscurePassword;
  final bool hasSubmitted;
  final AsyncValue<void> loginStatus;
  final PaperlessAuthMethod method;
  final String token;
  final bool obscureToken;
  final String mfaCode;

  /// The custom HTTP headers as typed: one `Name: value` pair per line. Once
  /// they are saved, the form only keeps their names.
  final String customHeaders;

  /// The names of the saved custom headers. Their values stay in the storage
  /// and are not shown again.
  final List<String> savedCustomHeaderNames;

  /// The chosen PKCS #12 file of the TLS client certificate, if any.
  final String? clientCertificateFileName;
  final Uint8List? clientCertificateBytes;
  final String clientCertificatePassword;

  /// Set when the last submit could not read the file with the password.
  final bool clientCertificateUnreadable;
  final String? connectedDisplayName;

  bool get isSubmitting => loginStatus.isLoading;

  bool get isTokenMethod => method == PaperlessAuthMethod.token;

  /// Null when [customHeaders] has a line that is not a valid header.
  Map<String, String>? get parsedCustomHeaders =>
      parseCustomHeaders(customHeaders);

  /// Custom headers are only sent over HTTPS, so the form doesn't accept them
  /// together with any other kind of server URL.
  bool get customHeadersNeedHttps {
    final headers = parsedCustomHeaders;
    final hasHeaders =
        (headers != null && headers.isNotEmpty) ||
        savedCustomHeaderNames.isNotEmpty;
    if (!hasHeaders || !_hasValidServerUrl) {
      return false;
    }

    return !allowsCustomHeaders(Uri.parse(serverUrl.trim()));
  }

  ClientCertificate? get clientCertificate {
    final bytes = clientCertificateBytes;
    if (bytes == null) {
      return null;
    }

    return ClientCertificate(
      fileName: clientCertificateFileName ?? '',
      bytes: bytes,
      password: clientCertificatePassword,
    );
  }

  /// A client certificate is part of TLS, so it can't work with any other
  /// kind of server URL.
  bool get clientCertificateNeedsHttps {
    if (clientCertificateBytes == null || !_hasValidServerUrl) {
      return false;
    }

    return !Uri.parse(serverUrl.trim()).isScheme('https');
  }

  bool get isValid {
    if (parsedCustomHeaders == null ||
        customHeadersNeedHttps ||
        clientCertificateNeedsHttps) {
      return false;
    }

    if (isTokenMethod) {
      return _hasValidServerUrl && token.trim().isNotEmpty;
    }

    return _hasValidServerUrl &&
        username.trim().isNotEmpty &&
        password.isNotEmpty;
  }

  bool get _hasValidServerUrl {
    final trimmed = serverUrl.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(trimmed);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  String? serverUrlError(String requiredMessage, String fullUrlMessage) {
    if (!hasSubmitted) {
      return null;
    }

    final trimmed = serverUrl.trim();
    if (trimmed.isEmpty) {
      return requiredMessage;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return fullUrlMessage;
    }

    return null;
  }

  String? usernameError(String requiredMessage) {
    if (!hasSubmitted || isTokenMethod) {
      return null;
    }

    if (username.trim().isEmpty) {
      return requiredMessage;
    }

    return null;
  }

  String? passwordError(String requiredMessage) {
    if (!hasSubmitted || isTokenMethod) {
      return null;
    }

    if (password.isEmpty) {
      return requiredMessage;
    }

    return null;
  }

  String? tokenError(String requiredMessage) {
    if (!hasSubmitted) {
      return null;
    }

    if (token.trim().isEmpty) {
      return requiredMessage;
    }

    return null;
  }

  String? customHeadersError(String invalidMessage, String httpsMessage) {
    if (!hasSubmitted) {
      return null;
    }

    if (parsedCustomHeaders == null) {
      return invalidMessage;
    }

    return customHeadersNeedHttps ? httpsMessage : null;
  }

  String? clientCertificateError(
    String unreadableMessage,
    String httpsMessage,
  ) {
    // Not only after a submit: picking a file can already fail.
    if (clientCertificateUnreadable) {
      return unreadableMessage;
    }

    return hasSubmitted && clientCertificateNeedsHttps ? httpsMessage : null;
  }

  LoginFormState copyWith({
    String? serverUrl,
    String? username,
    String? password,
    bool? obscurePassword,
    bool? hasSubmitted,
    AsyncValue<void>? loginStatus,
    PaperlessAuthMethod? method,
    String? token,
    bool? obscureToken,
    String? mfaCode,
    String? customHeaders,
    List<String>? savedCustomHeaderNames,
    String? clientCertificateFileName,
    Uint8List? clientCertificateBytes,
    String? clientCertificatePassword,
    bool? clientCertificateUnreadable,
    bool removeClientCertificate = false,
    String? connectedDisplayName,
  }) {
    return LoginFormState(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      hasSubmitted: hasSubmitted ?? this.hasSubmitted,
      loginStatus: loginStatus ?? this.loginStatus,
      method: method ?? this.method,
      token: token ?? this.token,
      obscureToken: obscureToken ?? this.obscureToken,
      mfaCode: mfaCode ?? this.mfaCode,
      customHeaders: customHeaders ?? this.customHeaders,
      savedCustomHeaderNames:
          savedCustomHeaderNames ?? this.savedCustomHeaderNames,
      clientCertificateFileName: removeClientCertificate
          ? null
          : clientCertificateFileName ?? this.clientCertificateFileName,
      clientCertificateBytes: removeClientCertificate
          ? null
          : clientCertificateBytes ?? this.clientCertificateBytes,
      clientCertificatePassword: removeClientCertificate
          ? ''
          : clientCertificatePassword ?? this.clientCertificatePassword,
      clientCertificateUnreadable: removeClientCertificate
          ? false
          : clientCertificateUnreadable ?? this.clientCertificateUnreadable,
      connectedDisplayName: connectedDisplayName ?? this.connectedDisplayName,
    );
  }
}
